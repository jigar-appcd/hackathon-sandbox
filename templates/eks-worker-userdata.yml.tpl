MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${resource_name}
    apiServerEndpoint: ${master_endpoint}
    certificateAuthority: ${cluster_ca}
    cidr: ${cluster_cidr}
  kubelet:
    config:
      maxPods: ${max_pods}
      clusterDNS: 
        - ${dns_cluster_ip}
    flags:
      - --max-pods=${max_pods}
      - --node-labels=nodegroup=${node_group},${node_labels}
      - --register-with-taints=${node_taints}
      - --image-gc-low-threshold=50
      - --image-gc-high-threshold=70
      - --registry-qps=50
      - --registry-burst=100
--BOUNDARY--