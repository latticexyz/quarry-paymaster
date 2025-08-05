import { debug } from "./debug";
import env from "./env";
import { sendUserOperation, UserOperationReceipt, waitForUserOperationReceipt } from "viem/account-abstraction";
import { formatAbiItemWithArgs, getAction } from "viem/utils";
import { getSmartAccountClient, bundlerClient, publicClient } from "./clients";
import { paymaster } from "./contract";
import { getRecord, Table } from "@latticexyz/store/internal";
import worldConfig from "@latticexyz/world/mud.config";
import storeConfig from "@latticexyz/store/mud.config";
import { resourceToHex, resourceToLabel } from "@latticexyz/common";

import { decodeErrorResult, formatEther, isHex, zeroAddress } from "viem";
import {
  getKeySchema,
  getSchemaTypes,
  getValueSchema,
  keySchemaToHex,
  valueSchemaToFieldLayoutHex,
  valueSchemaToHex,
} from "@latticexyz/protocol-parser/internal";
import { GrantsTable } from "./common";
import { getBalance } from "viem/actions";

export async function setup() {
  if (!env.NAMESPACE) {
    debug(`No NAMESPACE environment variable provided, skipping table setup`);
    return;
  }

  debug(`setting up table for namespace ${env.NAMESPACE}`);

  await ensureNamespace(env.NAMESPACE);
  await ensureTable({ table: GrantsTable });
  await ensureAllowance();
}

async function ensureNamespace(namespace: string) {
  const smartAccountClient = await getSmartAccountClient();
  const namespaceId = resourceToHex({ namespace, type: "namespace", name: "" });

  const { owner } = await getRecord(publicClient, {
    table: worldConfig.tables.world__NamespaceOwner,
    key: { namespaceId },
    address: paymaster.address,
  });

  if (owner === smartAccountClient.account.address) {
    debug(`namespace ${namespace} already exists and is owned by configured sponsor account`);
    return;
  }

  if (owner !== zeroAddress && owner !== smartAccountClient.account.address) {
    throw new Error(`namespace ${namespace} already exists and is owned by ${owner}`);
  }

  debug(`registering namespace ${namespace}`);

  const hash = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: paymaster.abi,
        to: paymaster.address,
        functionName: "registerNamespace",
        args: [namespaceId],
      },
    ],
  });

  debug(`waiting for user operation receipt for tx ${hash}`);
  const receipt = await getAction(bundlerClient, waitForUserOperationReceipt, "waitForUserOperationReceipt")({ hash });

  if (!receipt.success) {
    const errorMessage = formatRevertReason(receipt);
    debug(errorMessage);
    throw new Error(errorMessage);
  }

  debug(`successfully registered namespace ${namespace}`);
}

type EnsureTableOptions = {
  readonly table: Table;
};

async function ensureTable({ table }: EnsureTableOptions) {
  const smartAccountClient = await getSmartAccountClient();
  const keySchema = getSchemaTypes(getKeySchema(table));
  const valueSchema = getSchemaTypes(getValueSchema(table));

  const { exists } = await getRecord(publicClient, {
    table: storeConfig.tables.store__ResourceIds,
    key: { resourceId: table.tableId },
    address: paymaster.address,
  });

  if (exists) {
    debug(`table ${resourceToLabel(table)} already exists`);
    return;
  }

  const hash = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: paymaster.abi,
        to: paymaster.address,
        functionName: "registerTable",
        args: [
          table.tableId,
          valueSchemaToFieldLayoutHex(valueSchema),
          keySchemaToHex(keySchema),
          valueSchemaToHex(valueSchema),
          Object.keys(keySchema),
          Object.keys(valueSchema),
        ],
      },
    ],
  });

  debug(`waiting for user operation receipt for tx ${hash}`);
  const receipt = await getAction(bundlerClient, waitForUserOperationReceipt, "waitForUserOperationReceipt")({ hash });

  if (!receipt.success) {
    const errorMessage = formatRevertReason(receipt);
    debug(errorMessage);
    throw new Error(errorMessage);
  }

  debug(`successfully registered table ${resourceToLabel(table)}`);
}

async function ensureAllowance() {
  const smartAccountClient = await getSmartAccountClient();
  const sponsorAddress = smartAccountClient.account.address;
  const balance = await getBalance(smartAccountClient, { address: sponsorAddress });
  const gasBuffer = 1_000_000_000_000_000n;

  if (balance < gasBuffer) {
    console.log(`sponsor ${sponsorAddress} balance too low to top up: ${formatEther(balance)}`);
    return;
  }

  const hash = await getAction(
    smartAccountClient,
    sendUserOperation,
    "sendUserOperation",
  )({
    calls: [
      {
        abi: paymaster.abi,
        to: paymaster.address,
        functionName: "depositTo",
        args: [sponsorAddress],
        value: balance - gasBuffer,
      },
    ],
  });

  debug(`waiting for user operation receipt for tx ${hash}`);
  const receipt = await getAction(bundlerClient, waitForUserOperationReceipt, "waitForUserOperationReceipt")({ hash });

  if (!receipt.success) {
    const errorMessage = formatRevertReason(receipt);
    debug(errorMessage);
    throw new Error(errorMessage);
  }

  debug(`successfully topped up sponsor balance`);
}

function formatRevertReason(receipt: UserOperationReceipt): string {
  if (!isHex(receipt.reason)) {
    return `Failed to register namespace for an unknown reason.\n\nTransaction hash: ${receipt.receipt.transactionHash}`;
  }

  const reason = decodeErrorResult({ abi: paymaster.abi, data: receipt.reason });

  return formatAbiItemWithArgs(reason) + "\n\n" + `Transaction hash: ${receipt.receipt.transactionHash}`;
}
