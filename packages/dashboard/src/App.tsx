import { AccountButton } from "@latticexyz/entrykit/internal";
import { Synced } from "./mud/Synced";
import { Allowances } from "./Allowances";
import { Sponsor } from "./Sponsor";

export function App() {
  return (
    <>
      <div className="sticky top-0 p-4 flex justify-end">
        <AccountButton />
      </div>
      <div className="grid place-items-center p-16">
        <Synced
          fallback={({ message, percentage }) => (
            <div className="tabular-nums">
              {message} ({percentage.toFixed(1)}%)…
            </div>
          )}
        >
          <div className="grid grid-cols-2 gap-16">
            <div className="border border-dashed border-neutral-600 p-8 space-y-8">
              <div className="text-center space-y-2 flex flex-col items-center">
                <h1 className="text-4xl font-mono text-white">Sponsor</h1>
                <p className="max-w-72 text-sm text-pretty">
                  Grant a gas allowance to other accounts, allowing them to
                  spend some of your gas balance. You can claim back any unspent
                  allowance at any time.
                </p>
              </div>
              <Sponsor />
            </div>
            <div className="border border-dashed border-neutral-600 p-8 space-y-8">
              <div className="text-center space-y-2 flex flex-col items-center">
                <h1 className="text-4xl font-mono text-white">Allowances</h1>
                <p className="max-w-72 text-sm text-pretty">
                  Allowances you’ve received from sponsors. They are spent from
                  lowest to highest.
                </p>
              </div>
              <Allowances />
            </div>
          </div>
        </Synced>
      </div>
    </>
  );
}
