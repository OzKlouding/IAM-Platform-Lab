IAM Platform Lab

Purpose
This repository demonstrates a production-style Identity and Access Management platform built on Microsoft Entra ID and Azure. The focus is on automation, least privilege, auditability, and repeatable infrastructure using Terraform and GitHub Actions.

This is not a demo.
This repo mirrors how IAM foundations are designed, bootstrapped, and evolved in real environments.

What this repo demonstrates

Entra ID tenant governance patterns

Identity lifecycle automation using Infrastructure as Code

Secure Terraform remote state design

RBAC modeling and access boundaries

Separation of control plane and workload access

GitHub-driven deployment workflows

Security-first defaults and guardrails

Repository structure

docs/
Design and decision documentation. Written for security and platform reviewers.

00-overview.md
IAM platform goals, scope, and non-goals

01-architecture.md
Identity architecture, trust boundaries, and access flows

02-threat-model.md
IAM-specific threat modeling and mitigations

STATE_BACKEND.md
Terraform state strategy and security controls

infra/
Terraform code for identity and access foundations.
All changes are designed to be applied via automation.

scripts/
Bootstrap and helper scripts.
Used only to establish initial control plane prerequisites.

Current status

Terraform remote state fully bootstrapped

Secure Azure Storage backend with Entra authentication

Repo structure normalized for scale

Planned work
Week 1

Entra users and groups via Terraform

Role-based access models

Environment separation

Week 2

Application registrations and service principals

Workload identities

Managed identity patterns

Week 3

Conditional Access as code

Privileged Identity Management modeling

Access reviews

Week 4

GitHub Actions pipelines

Policy enforcement

Audit and logging integration

Audience
This repository is intended for cloud security engineers, IAM engineers, and platform teams evaluating how identity infrastructure should be designed and automated in Azure environments.