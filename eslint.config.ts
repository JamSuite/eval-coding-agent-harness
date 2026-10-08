import js from "@eslint/js";
import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";

// Type-aware rules, so that a floating promise or an unsafe `any` fails the
// gate rather than a run. Formatting is prettier's job, not ESLint's.
export default defineConfig(
    { ignores: ["node_modules/"] },
    js.configs.recommended,
    tseslint.configs.strictTypeChecked,
    {
        languageOptions: {
            parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
        },
    },
    {
        // node:test's describe() and it() return promises that the runner
        // itself awaits; awaiting them by hand would only add noise.
        files: ["**/*.test.ts"],
        rules: { "@typescript-eslint/no-floating-promises": "off" },
    },
);
