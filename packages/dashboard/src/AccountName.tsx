import type { Hex } from "viem";
import { TruncatedHex } from "./TruncatedHex";
import { useENS } from "./useENS";

export type Props = {
  address: Hex;
};

export function AccountName({ address }: Props) {
  const { data: ens } = useENS(address);
  return <>{ens?.name ?? <TruncatedHex hex={address} />}</>;
}
