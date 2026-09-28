// After an install: the extensions are in the editor, and the player that
// game/txt2gam.json names for this OS exists. Run with node from the root.
import { execFileSync } from 'node:child_process';
import { accessSync, constants, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const [lang, extensionsDir, userDataDir, cli] = process.argv.slice(2);
const listed = execFileSync(cli, ['--user-data-dir', userDataDir, '--extensions-dir', extensionsDir, '--list-extensions'], {
  encoding: 'utf8', shell: process.platform === 'win32',
}).toLowerCase();
const want = ['qsp.qsp-lsp', ...(lang === 'ru' ? ['ms-ceintl.vscode-language-pack-ru'] : [])];
for (const id of want) if (!listed.includes(id)) throw new Error(`extension ${id} is not installed:\n${listed}`);

const cfg = JSON.parse(readFileSync('game/txt2gam.json', 'utf8'));
const player = resolve('game', cfg.playerExecutable[process.platform]);
accessSync(player, process.platform === 'win32' ? constants.F_OK : constants.X_OK);
console.log(`ok: ${want.join(', ')}; player ${player}`);
