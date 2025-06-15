import time
import lgpio
import logging
from signal import signal, SIGTERM
import boto3
from datetime import datetime
import time
import os
from decimal import Decimal

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)

logger = logging.getLogger(__name__)

TABLE_NAME = os.getenv("TABLE_NAME", "eks-timeseries")
INTERVAL = int(os.getenv("WRITE_INTERVAL", "60"))
REGION = os.getenv("DYNAMO_REGION", "eu-west-1")
SAMPLING_INTERVAL = int(os.getenv("SAMPLING_INTERVAL", "20"))
PIN_TRIGGER = int(os.getenv("PIN_TRIGGER", "4"))
PIN_ECHO = int(os.getenv("PIN_ECHO", "17"))

dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)

def write_timeseries_entry(distance):
    now = datetime.utcnow()
    item = {
        "yyyymmdd": now.strftime("%Y%m%d"),
        "hhmmss": now.strftime("%H%M%S"),
        "distance": Decimal(str(distance))
    }
    print("Writing item:", item)
    table.put_item(Item=item)

class UltrasonicSensor:
    def __init__(self):
        self.running = True
        self.gpio_handle = None
        signal(SIGTERM, self.handle_shutdown)
        
    def initialize(self):
        try:
            self.gpio_handle = lgpio.gpiochip_open(0)
            lgpio.gpio_claim_output(self.gpio_handle, PIN_TRIGGER)
            lgpio.gpio_claim_input(self.gpio_handle, PIN_ECHO)
            lgpio.gpio_write(self.gpio_handle, PIN_TRIGGER, 0)
            time.sleep(2)  # Sensor settling time
            return True
        except Exception as e:
            logger.error(f"Initialization failed: {str(e)}")
            return False

    def measure_distance(self):
        try:
            lgpio.gpio_write(self.gpio_handle, PIN_TRIGGER, 1)
            time.sleep(0.00001)
            lgpio.gpio_write(self.gpio_handle, PIN_TRIGGER, 0)
            
            timeout = time.time() + 0.1  # 100ms timeout
            while lgpio.gpio_read(self.gpio_handle, PIN_ECHO) == 0:
                if time.time() > timeout:
                    raise TimeoutError("Echo pulse start timeout")
                pulse_start = time.time()
            
            while lgpio.gpio_read(self.gpio_handle, PIN_ECHO) == 1:
                if time.time() > timeout:
                    raise TimeoutError("Echo pulse end timeout")
                pulse_end = time.time()
            
            distance = round((pulse_end - pulse_start) * 17150, 2)
            return distance
        except Exception as e:
            logger.warning(f"Measurement error: {str(e)}")
            return None

    def handle_shutdown(self, signum, frame):
        logger.info("Shutting down gracefully...")
        self.running = False

    def run(self):
        if not self.initialize():
            return
        
        while self.running:
            distance = self.measure_distance()
            if distance is not None:
                logger.info(f"Distance: {distance} cm")
                write_timeseries_entry(distance)
            else:
                logger.warning("Invalid measurement")
            for _ in range(SAMPLING_INTERVAL):
                if not self.running:
                    break
                time.sleep(1)
        
        self.cleanup()

    def cleanup(self):
        if self.gpio_handle:
            lgpio.gpiochip_close(self.gpio_handle)
        logger.info("GPIO resources released")

if __name__ == "__main__":
    sensor = UltrasonicSensor()
    sensor.run()