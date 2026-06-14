// @ts-expect-error standalone script, @types/node is missing
import fs from "node:fs";
// @ts-expect-error standalone script, @types/node is missing
import path from "node:path";

const [arch, packageJsonPath] =
  // @ts-expect-error standalone script, @types/node is missing
  (process.argv as string[]).slice(2);

const isRecord = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null;

const isList = (v: unknown): v is string | string[] =>
  typeof v === "string" ||
  (Array.isArray(v) && v.every((c) => typeof c === "string"));

// prettier-ignore
/**
 * from https://github.com/npm/npm-install-checks/blob/v9.0.0/lib/index.js#L59-L83
 *
 * LICENSE
 * ---
 * Copyright (c) Robert Kowalski and Isaac Z. Schlueter ("Authors")
 * All rights reserved.
 *
 * The BSD License
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
const checkList = (value: string, list: string | string[]) => {
  if (typeof list === 'string') {
    list = [list]
  }
  if (list.length === 1 && list[0] === 'any') {
    return true
  }
  // match none of the negated values, and at least one of the
  // non-negated values, if any are present.
  let negated = 0
  let match = false
  for (const entry of list) {
    const negate = entry.charAt(0) === '!'
    const test = negate ? entry.slice(1) : entry
    if (negate) {
      negated++
      if (value === test) {
        return false
      }
    } else {
      match = match || value === test
    }
  }
  return match || negated === list.length
}

let pkg: unknown;
try {
  pkg = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
} catch {}
if (
  isRecord(pkg) &&
  !(
    (!isList(pkg.os) || checkList("linux", pkg.os)) &&
    (!isList(pkg.cpu) ||
      checkList(arch === "arm64" ? "arm64" : "x64", pkg.cpu)) &&
    (!isList(pkg.libc) || checkList("glibc", pkg.libc))
  )
) {
  fs.rmSync(path.dirname(packageJsonPath), { recursive: true, force: true });
}
