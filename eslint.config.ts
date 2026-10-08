import js from "@eslint/js";
import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";

// Type-aware rules, so that a floating promise or an unsafe `any` fails the
// gate rather than a run. Formatting is prettier's job, not ESLint's.
export default defineConfig({ ignores: ["node_modules/"] }, js.configs.recommended, tseslint.configs.strictTypeChecked, {
    languageOptions: {
        parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
});
