apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${eks_worker_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
%{ for name, arn in eks_admin_arns ~}
    - rolearn: ${arn}
      username: ${name}
      groups:
        - system:masters
%{ endfor ~}
%{ if map_roles != null ~}
    ${indent(4, yamlencode(map_roles))}
%{ endif ~}