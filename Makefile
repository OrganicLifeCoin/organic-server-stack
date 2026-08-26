.PHONY: check compose-config

check:
	@set -e; for test_script in tests/*.test.sh; do bash "$$test_script"; done

compose-config:
	docker compose --env-file .env.example config --quiet
