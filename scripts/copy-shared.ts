#!/usr/bin/env -S deno run -A
/**
 * Copie le build compilé de packages/shared/npm (esm, script, package.json, README.md)
 * dans tous les dossiers node_modules/@lotso-trading/shared détectés dans le workspace.
 */

import { fileURLToPath, pathToFileURL } from "node:url";

const rootDir = new URL("../", import.meta.url);
const rootPath = fileURLToPath(rootDir);
const sharedNpmDir = new URL("packages/shared/npm/", rootDir);
const servicesDir = new URL("services/", rootDir);

const DIRS_TO_COPY = ["esm", "script"] as const;
const FILES_TO_COPY = ["package.json", "README.md"] as const;

async function exists(path: string | URL): Promise<boolean> {
    try {
        await Deno.stat(path);
        return true;
    } catch {
        return false;
    }
}

async function copyDir(src: URL, dest: URL): Promise<void> {
    await Deno.mkdir(dest, { recursive: true });
    for await (const entry of Deno.readDir(src)) {
        const suffix = entry.isDirectory ? "/" : "";
        const srcEntry = new URL(`${entry.name}${suffix}`, src);
        const destEntry = new URL(`${entry.name}${suffix}`, dest);
        if (entry.isDirectory) {
            await copyDir(srcEntry, destEntry);
        } else if (entry.isFile) {
            await Deno.copyFile(srcEntry, destEntry);
        }
    }
}

async function collectNodeModulesTargets(nodeModulesUrl: URL, targets: Set<string>): Promise<void> {
    const directPkg = new URL("@lotso-trading/shared", nodeModulesUrl);
    if (await exists(directPkg)) {
        targets.add(await Deno.realPath(directPkg));
    }

    const denoStore = new URL(".deno/", nodeModulesUrl);
    if (!(await exists(denoStore))) return;

    for await (const entry of Deno.readDir(denoStore)) {
        if (!entry.isDirectory || !entry.name.startsWith("@lotso-trading+shared@")) continue;
        const pkgDir = new URL(`${entry.name}/node_modules/@lotso-trading/shared`, denoStore);
        if (await exists(pkgDir)) {
            targets.add(await Deno.realPath(pkgDir));
        }
    }
}

async function findTargetDirs(): Promise<string[]> {
    const targets = new Set<string>();
    await collectNodeModulesTargets(new URL("node_modules/", rootDir), targets);

    if (await exists(servicesDir)) {
        for await (const entry of Deno.readDir(servicesDir)) {
            if (!entry.isDirectory) continue;
            await collectNodeModulesTargets(
                new URL(`${entry.name}/node_modules/`, servicesDir),
                targets
            );
        }
    }

    return [...targets];
}

export async function copySharedToNodeModules(): Promise<string[]> {
    const esmEntry = new URL("esm/index.js", sharedNpmDir);
    const pkgJsonUrl = new URL("package.json", sharedNpmDir);

    if (!(await exists(esmEntry)) || !(await exists(pkgJsonUrl))) {
        throw new Error(
            "Build packages/shared/npm introuvable. Exécutez `deno run build:copie` ou `deno task --cwd packages/shared build:npm`."
        );
    }

    const targets = await findTargetDirs();
    if (targets.length === 0) {
        throw new Error(
            "Aucun dossier node_modules/@lotso-trading/shared trouvé. Exécutez d'abord `deno install`."
        );
    }

    const pkg = JSON.parse(await Deno.readTextFile(pkgJsonUrl)) as { version?: string };
    const version = pkg.version || "unknown";

    for (const targetPath of targets) {
        const targetUrl = pathToFileURL(targetPath.endsWith("/") ? targetPath : `${targetPath}/`);

        for (const dirName of DIRS_TO_COPY) {
            const srcDir = new URL(`${dirName}/`, sharedNpmDir);
            if (!(await exists(srcDir))) continue;
            const destDir = new URL(`${dirName}/`, targetUrl);
            if (await exists(destDir)) {
                await Deno.remove(destDir, { recursive: true });
            }
            await copyDir(srcDir, destDir);
        }

        for (const fileName of FILES_TO_COPY) {
            const srcFile = new URL(fileName, sharedNpmDir);
            if (!(await exists(srcFile))) continue;
            const destFile = new URL(fileName, targetUrl);
            if (await exists(destFile)) {
                await Deno.remove(destFile);
            }
            await Deno.copyFile(srcFile, destFile);
        }

        const relPath = targetPath.startsWith(rootPath)
            ? targetPath.slice(rootPath.length)
            : targetPath;
        console.log(`✅ @lotso-trading/shared v${version} copié dans ${relPath}`);
    }

    console.log(`🎯 Copie terminée (${targets.length} cible(s) mise(s) à jour).`);
    return targets;
}

if (import.meta.main) {
    await copySharedToNodeModules();
}
