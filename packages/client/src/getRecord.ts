import { Table } from "@latticexyz/config";
import { encodeKey, Key, State, TableRecord } from "@latticexyz/stash/internal";

// TODO: move this into stash

export type GetRecordArgs<
  table extends Table = Table,
  defaultValue extends Omit<TableRecord<table>, keyof Key<table>> | undefined = undefined,
> = {
  state: State;
  table: table;
  key: Key<table>;
  defaultValue?: defaultValue;
};

export type GetRecordResult<
  table extends Table = Table,
  defaultValue extends Omit<TableRecord<table>, keyof Key<table>> | undefined = undefined,
> = defaultValue extends undefined ? TableRecord<table> | undefined : TableRecord<table>;

export function getRecord<
  const table extends Table,
  const defaultValue extends Omit<TableRecord<table>, keyof Key<table>> | undefined = undefined,
>({ state, table, key, defaultValue }: GetRecordArgs<table, defaultValue>): GetRecordResult<table, defaultValue> {
  const { namespaceLabel, label } = table;
  return (state.records[namespaceLabel]?.[label]?.[encodeKey({ table, key })] ?? defaultValue) as never;
}
