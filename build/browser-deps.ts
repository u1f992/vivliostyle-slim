import { deps } from "./nativeDeps.ts";

const [distro] = // @ts-expect-error standalone script, @types/node is missing
  (process.argv as string[]).slice(2);

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null;

const isStringArray = (arr: unknown): arr is string[] =>
  Array.isArray(arr) && arr.every((dep) => typeof dep === "string");

const entry = isRecord(deps) ? deps[distro] : undefined;
const pick = (key: string): string[] => {
  const value = isRecord(entry) ? entry[key] : undefined;
  return isStringArray(value) ? value : [];
};
const packages = [...new Set([...pick("chromium"), ...pick("firefox")])];

// @ts-expect-error standalone script, @types/node is missing
process.stdout.write(packages.join(" "));
