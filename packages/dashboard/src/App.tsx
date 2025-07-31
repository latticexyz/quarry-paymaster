import { useCallback, useEffect, useState } from "react";
import { adminClient, grantorClient, publicClient, smartAccountClient } from "./clients";
import { sync } from "./sync";
import { getBalance } from "viem/actions";
import { formatEther, padHex, parseEther } from "viem/utils";
import { useStash } from "./useStash";
import { stash } from "./stash";
import { getRecord } from "./getRecord";
import config from "contracts/mud.config";
import {
  setGrantAllowance,
  grantAllowance,
  registerPass,
  claim,
  issuePass,
  registerNamespace,
  incrementCounter,
} from "./actions";
import { hexToResource } from "@latticexyz/common";
import { chain } from "./chain";

const tables = config.namespaces.root.tables;
const passId = padHex("0x01");

export const App = () => {
  const [adminBalance, setAdminBalance] = useState(0n);
  const [grantorBalance, setGrantorBalance] = useState(0n);
  const [userBalance, setUserBalance] = useState(0n);
  const [namespace, setNamespace] = useState("");
  const [claimAmount, setClaimAmount] = useState("");
  const [claimInterval, setClaimInterval] = useState(0);
  const [passValidity, setPassValidity] = useState(0);

  const updateBalance = useCallback(async () => {
    setAdminBalance(await getBalance(publicClient, { address: adminClient.account.address }));
    setGrantorBalance(await getBalance(publicClient, { address: grantorClient.account.address }));
    setUserBalance(await getBalance(publicClient, { address: smartAccountClient.account.address }));
  }, []);

  useEffect(() => {
    sync();
  }, []);

  useEffect(() => {
    const interval = setInterval(updateBalance, 1000);
    return () => clearInterval(interval);
  }, [updateBalance]);

  const grantorAllowance = useStash(
    stash,
    (state) =>
      getRecord({ state, table: tables.Grantor, key: { grantor: grantorClient.account.address } })?.allowance ?? 0n,
  );

  const userAllowance = useStash(
    stash,
    (state) =>
      getRecord({ state, table: tables.Allowance, key: { user: smartAccountClient.account.address } })?.allowance ?? 0n,
  );

  const lastClaimed = useStash(
    stash,
    (state) =>
      getRecord({ state, table: tables.PassHolder, key: { user: smartAccountClient.account.address, passId } })
        ?.lastClaimed,
  );

  const lastRenewed = useStash(
    stash,
    (state) =>
      getRecord({ state, table: tables.PassHolder, key: { user: smartAccountClient.account.address, passId } })
        ?.lastRenewed,
  );

  const namespaceOwners = useStash(stash, (state) => state.records.world.NamespaceOwner);

  return (
    <>
      <div className="table">
        <div className="td">Admin</div>
        <div className="td">Grantor</div>
        <div className="td">User</div>

        <div className="td">{adminClient.account?.address.slice(0, 10)}...</div>
        <div className="td">{grantorClient.account?.address.slice(0, 10)}...</div>
        <div className="td">{smartAccountClient.account?.address}</div>

        <div className="td">ETH Balance: {formatEther(adminBalance)}</div>
        <div className="td">ETH Balance: {formatEther(grantorBalance)}</div>
        <div className="td">ETH Balance: {formatEther(userBalance)}</div>

        <div className="td"></div>
        <div className="td">Grant Allowance: {formatEther(grantorAllowance)}</div>
        <div className="td">User Allowance: {formatEther(userAllowance)}</div>

        <div className="td">
          <button onClick={() => setGrantAllowance(parseEther("1"))}>Set grant allowance for grantor to 1 ETH</button>
        </div>
        <div className="td">
          <button onClick={() => grantAllowance(parseEther("0.1"), smartAccountClient.account.address)}>
            Grant 0.1 ETH allowance to user
          </button>

          <input
            placeholder="claim amount"
            value={claimAmount}
            onChange={(e) => setClaimAmount(e.target.value)}
          ></input>
          <input
            placeholder="claim interval"
            value={claimInterval}
            onChange={(e) => setClaimInterval(Number(e.target.value))}
          ></input>
          <input
            placeholder="pass validity"
            value={passValidity}
            onChange={(e) => setPassValidity(Number(e.target.value))}
          ></input>
          <button
            onClick={() => registerPass(passId, parseEther(claimAmount), BigInt(claimInterval), BigInt(passValidity))}
          >
            Register new {claimAmount}/{claimInterval}s/{passValidity}s pass
          </button>
          <button onClick={() => issuePass(passId, smartAccountClient.account.address)}>Issue pass to user</button>
        </div>
        <div className="td">
          <button onClick={() => claim(passId, smartAccountClient.account.address)}>Claim from pass</button>
          <div>
            Last claimed: {lastClaimed === 0n ? "never" : new Date(Number(lastClaimed) * 1000).toLocaleTimeString()}
          </div>
          <div>Last renewed: {new Date(Number(lastRenewed) * 1000).toLocaleTimeString()}</div>
          <input placeholder="namespace" value={namespace} onChange={(e) => setNamespace(e.target.value)}></input>
          <button onClick={() => registerNamespace(namespace)}>Register new namespace</button>
          {"counter" in chain.contracts && <button onClick={() => incrementCounter()}>Increment counter</button>}
        </div>
      </div>
      <div>
        Namespaces:
        <ul>
          {Object.values(namespaceOwners).map((namespaceOwner) => (
            <li>{hexToResource(namespaceOwner.namespaceId).namespace}</li>
          ))}
        </ul>
      </div>
    </>
  );
};
