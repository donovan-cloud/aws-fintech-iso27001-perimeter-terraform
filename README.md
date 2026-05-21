# AWS FinTech ISO/IEC 27001 Secure Perimeter Baseline (Terraform)

An enterprise-grade, declarative Infrastructure-as-Code blueprint designed to deploy an isolated, audit-ready network perimeter mapping directly to **ISO/IEC 27001:2022 Annex A** security controls. 

## 📋 Control Mapping Matrix

| ISO 27001 Control Clause | Architecture Implementation | Resource Mapping |
| :--- | :--- | :--- |
| **A.10.1** (Cryptographic controls) | Enforced Customer Managed Key (CMK) with automated 365-day rotation policies enabled. | `aws_kms_key` |
| **A.12.4** (Event logging) | Continuous network logging with 1-minute aggregation granularity routed to an encrypted CloudWatch Log Group. | `aws_flow_log`, `aws_cloudwatch_log_group` |
| **A.13.1** (Network security management) | Multi-tier layout completely isolating database tiers with a default zero-trust fallback security structure. | `aws_vpc`, `aws_default_security_group` |

## 🚀 Architectural Guardrails Deployed
* **Zero-Trust Default Security Group:** Automatically captures the native default security group and strips all ingress/egress rules, mitigating configuration errors.
* **Isolated Cryptographic Boundaries:** The CloudWatch audit pipeline is fully wrapped and encrypted at rest using a dedicated, auditable KMS key mechanism.
