// Directory plugin entrypoint: V2 loads configured plugin directories through
// their index.ts. The implementation stays in the sibling file so the existing
// flat symlink and this directory share one source.
export { default } from '../delegation-protocol.ts';
