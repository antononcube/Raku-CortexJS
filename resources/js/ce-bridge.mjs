import readline from 'node:readline';
import { ComputeEngine } from '@cortex-js/compute-engine';

const BRIDGE_VERSION = '0.0.1';
const ce = new ComputeEngine();

function ok(id, result) {
  return { id, ok: true, result };
}

function fail(id, error) {
  return {
    id,
    ok: false,
    error: {
      name: error?.name ?? 'Error',
      message: error?.message ?? String(error),
    },
  };
}

function toMathJSON(expr) {
  if (expr && typeof expr === 'object') {
    if (Object.prototype.hasOwnProperty.call(expr, 'json')) return expr.json;
    if (typeof expr.toJSON === 'function') return expr.toJSON();
  }
  return expr;
}

function handleRequest(req) {
  const { id = null, op, args = {} } = req ?? {};

  switch (op) {
    case 'ping':
      return ok(id, { pong: true });

    case 'version':
      return ok(id, {
        backend: '@cortex-js/compute-engine',
        node: process.version,
        bridge: BRIDGE_VERSION,
      });

    case 'parse_latex': {
      const expr = ce.parse(args.latex ?? '');
      return ok(id, toMathJSON(expr));
    }

    case 'box': {
      const expr = ce.box(args.expr);
      return ok(id, toMathJSON(expr));
    }

    case 'simplify': {
      const expr = ce.box(args.expr).simplify();
      return ok(id, toMathJSON(expr));
    }

    case 'assign': {
      const expr = ce.assign(args.id, args.expr);
      return ok(id, toMathJSON(expr));
    }

    case 'evaluate': {
      const expr = ce.box(args.expr).evaluate();
      return ok(id, toMathJSON(expr));
    }

    case 'n': {
      const expr = ce.box(args.expr).N();
      return ok(id, toMathJSON(expr));
    }

    case 'expand': {
      const expr = ce.box(args.expr).expand();
      return ok(id, toMathJSON(expr));
    }

    case 'expand_all': {
      const expr = ce.box(['ExpandAll', args.expr]).evaluate();
      return ok(id, toMathJSON(expr));
    }

    case 'factor': {
      const expr = ce.box(['Factor', args.expr]).evaluate();
      return ok(id, toMathJSON(expr));
    }

    case 'solve': {
      const solutions = ce.box(args.expr).solve();
      return ok(id, solutions?.map(toMathJSON) ?? null);
    }

    case 'to_latex': {
      const expr = ce.box(args.expr);
      return ok(id, expr.latex);
    }

    default:
      return {
        id,
        ok: false,
        error: {
          name: 'UnknownOperation',
          message: `Unknown op: ${String(op)}`,
        },
      };
  }
}

const rl = readline.createInterface({
  input: process.stdin,
  crlfDelay: Infinity,
});

rl.on('line', (line) => {
  if (!line.trim()) return;

  let req;
  try {
    req = JSON.parse(line);
  } catch (error) {
    process.stdout.write(`${JSON.stringify(fail(null, { name: 'BadJSON', message: error.message }))}\n`);
    return;
  }

  try {
    process.stdout.write(`${JSON.stringify(handleRequest(req))}\n`);
  } catch (error) {
    process.stdout.write(`${JSON.stringify(fail(req?.id ?? null, error))}\n`);
  }
});
