#!/usr/bin/env python3
import argparse
from pathlib import Path


def load_domains(path: Path):
    if not path.exists():
        return []
    domains = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        domains.append(line)
    return sorted(set(domains))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--domains-file", required=True)
    parser.add_argument("--output-file", required=True)
    parser.add_argument("--auth-domain", required=True)
    parser.add_argument("--base-domain", required=True)
    args = parser.parse_args()

    domains_file = Path(args.domains_file)
    output_file = Path(args.output_file)
    auth_domain = args.auth_domain.strip()
    base_domain = args.base_domain.strip()

    domains = load_domains(domains_file)

    dev_suffix = f".dev.{base_domain}"
    a0_suffix = f".a0.{base_domain}"

    rules = []

    # Auth portal itself must remain reachable
    rules.append(
        {
            "domain": auth_domain,
            "policy": "bypass",
        }
    )

    # Reusable wildcard rules for all tenant apps
    rules.append(
        {
            "domain": f"*.dev.{base_domain}",
            "policy": "one_factor",
            "subject": ["group:dev_users"],
        }
    )

    rules.append(
        {
            "domain": f"*.a0.{base_domain}",
            "policy": "one_factor",
            "subject": ["group:a0_users"],
        }
    )

    # Any other protected exact domains from the watcher file
    extra_domains = []
    for domain in domains:
        if domain == auth_domain:
            continue
        if domain.endswith(dev_suffix):
            continue
        if domain.endswith(a0_suffix):
            continue
        extra_domains.append(domain)

    for domain in sorted(set(extra_domains)):
        rules.append(
            {
                "domain": domain,
                "policy": "one_factor",
            }
        )

    lines = ["rules:"]
    for rule in rules:
        lines.append(f"  - domain: \"{rule['domain']}\"")
        lines.append(f"    policy: {rule['policy']}")
        if "subject" in rule:
            lines.append("    subject:")
            for subject in rule["subject"]:
                lines.append(f"      - \"{subject}\"")

    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
