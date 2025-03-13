affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/compute-type
          operator: In
          values:
          - hybrid
ipam:
  mode: cluster-pool
  operator:
    clusterPoolIPv4MaskSize: 24
    clusterPoolIPv4PodCIDRList:
    - ${remote_pod_cidr}
operator:
  unmanagedPodWatcher:
    restart: false
  replicas: 1
bgpControlPlane:
  enabled: false
k8sServiceHost: ${k8s_service_host}
k8sServicePort: 443

enableEnvoyConfig: false
envoy:
  enabled: false

