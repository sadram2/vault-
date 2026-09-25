#!/bin/sh

export VAULT_ADDR="http://127.0.0.1:8200"

echo "======================================"
echo "Vault unseal agent started"
echo "VAULT_ADDR=$VAULT_ADDR"
echo "======================================"

while true; do

    echo ""
    echo "Checking Vault status..."

    vault status
    STATUS=$?

    echo "Vault status exit code: $STATUS"

    # 0 = initialized and unsealed
    if [ "$STATUS" -eq 0 ]; then
        echo "Vault is unsealed"
        sleep 10
        continue
    fi

    # 2 = initialized but sealed
    if [ "$STATUS" -eq 2 ]; then

        echo "Vault is sealed"
        echo "Starting unseal process..."

        for KEY in key1 key2 key3 key4 key5; do

            echo ""
            echo "Checking Vault status before submitting $KEY..."

            vault status >/dev/null 2>&1
            STATUS=$?

            if [ "$STATUS" -eq 0 ]; then
                echo "Vault became unsealed"
                break
            fi

            echo "Submitting $KEY"

            KEY_FILE="/vault/unseal-keys/$KEY"

            if [ ! -f "$KEY_FILE" ]; then
                echo "ERROR: Key file does not exist: $KEY_FILE"
                continue
            fi

            echo "Using key file: $KEY_FILE"

            vault operator unseal "$(cat "$KEY_FILE")"

            UNSEAL_STATUS=$?

            echo "Unseal command exit code: $UNSEAL_STATUS"

            sleep 1

        done

        echo ""
        echo "Unseal attempts completed. Checking Vault again..."

        vault status
        STATUS=$?

        echo "Vault status after unseal attempts: $STATUS"

        sleep 10

        continue
    fi

    # Vault is not initialized / not available
    echo "Vault is not ready. status=$STATUS"

    sleep 5

done
