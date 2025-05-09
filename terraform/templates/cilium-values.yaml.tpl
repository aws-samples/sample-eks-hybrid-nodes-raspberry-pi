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
  replicas: 1
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: eks.amazonaws.com/compute-type
            operator: In
            values:
              - hybrid
  unmanagedPodWatcher:
    restart: false
bgpControlPlane:
  enabled: false
k8sServiceHost: ${k8s_service_host}
k8sServicePort: 443

enableEnvoyConfig: false
envoy:
  enabled: false

kubeProxyReplacement: true

loadBalancer:
  serviceTopology: true