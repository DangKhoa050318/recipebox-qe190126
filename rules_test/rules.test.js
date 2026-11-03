// Tests firestore.rules against the Firestore emulator.
// Run from the project root: firebase emulators:exec --only firestore --project demo-test "npm --prefix rules_test test"
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  addDoc,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
  Timestamp,
} from 'firebase/firestore';

const ALICE = 'alice';
const BOB = 'bob';

const key = (uid, name) =>
  createHash('sha256').update(`${uid}|${name.trim().toLowerCase()}`, 'utf8').digest('hex');

const recipe = (uid, overrides = {}) => {
  const data = {
    userId: uid,
    name: 'Pho Bo',
    category: 'Breakfast',
    difficulty: 'Medium',
    cookTime: 90,
    servings: null,
    favorite: false,
    notes: '',
    createdAt: serverTimestamp(),
    ...overrides,
  };
  data.id = key(uid, String(data.name ?? ''));
  return data;
};

let env;
const db = (uid) =>
  uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();

// Writes a recipe the way the app does (document id = key).
const save = (uid, data, asUser = uid) =>
  setDoc(doc(db(asUser), 'recipes', key(uid, String(data.name))), data);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-recipebox',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(() => env.clearFirestore());
after(() => env.cleanup());

describe('create', () => {
  test('valid recipe is accepted', () => assertSucceeds(save(ALICE, recipe(ALICE))));

  test('limits are accepted: name 80, cookTime 1 and 600, servings 1 and 20, notes 300', async () => {
    await assertSucceeds(save(ALICE, recipe(ALICE, {
      name: 'N'.repeat(80), cookTime: 600, servings: 20, notes: 'n'.repeat(300),
    })));
    await assertSucceeds(save(ALICE, recipe(ALICE, { name: 'Toast', cookTime: 1, servings: 1 })));
  });

  test('a recipe without optional fields is accepted', async () => {
    const { servings, favorite, notes, id, ...minimal } = recipe(ALICE);
    await assertSucceeds(save(ALICE, minimal));
  });

  const bad = {
    'missing name': { name: undefined },
    'empty name': { name: '' },
    'spaces-only name': { name: '    ' },
    'name of 81': { name: 'N'.repeat(81) },
    'non-string name': { name: 42 },
    'unknown category': { category: 'Snack' },
    'lower-case category': { category: 'lunch' },
    'missing category': { category: undefined },
    'unknown difficulty': { difficulty: 'Expert' },
    'missing difficulty': { difficulty: undefined },
    'missing cookTime': { cookTime: undefined },
    'cookTime 0': { cookTime: 0 },
    'cookTime 601': { cookTime: 601 },
    'cookTime 2.5': { cookTime: 2.5 },
    'cookTime as text': { cookTime: '30' },
    'servings 0': { servings: 0 },
    'servings 21': { servings: 21 },
    'servings 1.5': { servings: 1.5 },
    'servings as text': { servings: '4' },
    'notes of 301': { notes: 'n'.repeat(301) },
    'favorite not a bool': { favorite: 'yes' },
    'missing createdAt': { createdAt: undefined },
    'unknown extra field': { rating: 5 },
  };
  for (const [name, overrides] of Object.entries(bad)) {
    test(`refuses ${name}`, () => {
      const data = recipe(ALICE, overrides);
      delete data.id; // only the broken field should cause the refusal
      for (const k of Object.keys(data)) if (data[k] === undefined) delete data[k];
      return assertFails(
        setDoc(doc(db(ALICE), 'recipes', key(ALICE, String(overrides.name ?? 'Pho Bo'))), data),
      );
    });
  }

  test('refuses a recipe saved for another person', () =>
    assertFails(save(BOB, recipe(BOB), ALICE)));

  test('refuses a recipe with userId of another person under own key', () =>
    assertFails(setDoc(doc(db(ALICE), 'recipes', key(ALICE, 'Pho Bo')), { ...recipe(ALICE), userId: BOB })));

  test('refuses a random document id', () => assertFails(addDoc(collection(db(ALICE), 'recipes'), recipe(ALICE))));

  test('refuses a mismatching id field', () =>
    assertFails(save(ALICE, { ...recipe(ALICE), id: 'something-else' })));

  test('refuses visitors', () =>
    assertFails(setDoc(doc(db(null), 'recipes', key(ALICE, 'Pho Bo')), recipe(ALICE))));
});

describe('duplicates', () => {
  beforeEach(() => save(ALICE, recipe(ALICE)));

  test('same name with different case is refused', () =>
    assertFails(save(ALICE, recipe(ALICE, { name: 'pho bo', cookTime: 30 }))));

  test('exact same recipe again is refused', () => assertFails(save(ALICE, recipe(ALICE))));

  test('duplicate with a client timestamp is refused', () =>
    assertFails(save(ALICE, recipe(ALICE, { name: ' PHO BO ', createdAt: Timestamp.now() }))));

  test('another person may save the same name', () => assertSucceeds(save(BOB, recipe(BOB))));
});

describe('read', () => {
  beforeEach(async () => {
    await save(ALICE, recipe(ALICE));
    await save(BOB, recipe(BOB, { name: 'Banh Mi' }));
  });

  test('owner can read own recipe', () =>
    assertSucceeds(getDoc(doc(db(ALICE), 'recipes', key(ALICE, 'Pho Bo')))));

  test('owner can query own recipes', () =>
    assertSucceeds(getDocs(query(collection(db(ALICE), 'recipes'), where('userId', '==', ALICE)))));

  test("cannot read another person's recipe", () =>
    assertFails(getDoc(doc(db(ALICE), 'recipes', key(BOB, 'Banh Mi')))));

  test('cannot list the whole collection', () => assertFails(getDocs(collection(db(ALICE), 'recipes'))));

  test("cannot query another person's recipes", () =>
    assertFails(getDocs(query(collection(db(ALICE), 'recipes'), where('userId', '==', BOB)))));

  test('visitors cannot read', () =>
    assertFails(getDoc(doc(db(null), 'recipes', key(ALICE, 'Pho Bo')))));
});

// Reads a document as stored, bypassing the rules.
const stored = async (id) => {
  let data;
  await env.withSecurityRulesDisabled(async (ctx) => {
    data = (await getDoc(doc(ctx.firestore(), 'recipes', id))).data();
  });
  return data;
};

describe('update and delete', () => {
  const aliceId = key(ALICE, 'Pho Bo');
  beforeEach(() => save(ALICE, recipe(ALICE)));

  test('owner can toggle favorite', () =>
    assertSucceeds(updateDoc(doc(db(ALICE), 'recipes', aliceId), { favorite: true })));

  test('owner can edit fields that keep the same id', () =>
    assertSucceeds(updateDoc(doc(db(ALICE), 'recipes', aliceId), {
      name: 'PHO BO', difficulty: 'Hard', cookTime: 120, servings: 4, notes: 'Beef broth',
    })));

  test('owner can rename (move to the new id) in one batch', async () => {
    const old = await stored(aliceId);
    const fs = db(ALICE);
    const batch = writeBatch(fs);
    const newId = key(ALICE, 'Pho Ga');
    batch.delete(doc(fs, 'recipes', aliceId));
    batch.set(doc(fs, 'recipes', newId), { ...old, name: 'Pho Ga', id: newId });
    await assertSucceeds(batch.commit());
  });

  test('renaming onto an existing recipe is refused', async () => {
    await save(ALICE, recipe(ALICE, { name: 'Banh Mi' }));
    const old = await stored(aliceId);
    const fs = db(ALICE);
    const batch = writeBatch(fs);
    const newId = key(ALICE, 'Banh Mi');
    batch.delete(doc(fs, 'recipes', aliceId));
    batch.set(doc(fs, 'recipes', newId), { ...old, name: 'Banh Mi', id: newId });
    await assertFails(batch.commit());
  });

  test('editing the name without moving the id is refused', () =>
    assertFails(updateDoc(doc(db(ALICE), 'recipes', aliceId), { name: 'Other' })));

  test('bad data in an update is refused', async () => {
    const ref = doc(db(ALICE), 'recipes', aliceId);
    await assertFails(updateDoc(ref, { cookTime: 0 }));
    await assertFails(updateDoc(ref, { cookTime: 700 }));
    await assertFails(updateDoc(ref, { servings: 30 }));
    await assertFails(updateDoc(ref, { category: 'Snack' }));
    await assertFails(updateDoc(ref, { difficulty: 'Expert' }));
    await assertFails(updateDoc(ref, { notes: 'n'.repeat(301) }));
    await assertFails(updateDoc(ref, { createdAt: Timestamp.now() }));
  });

  test('cannot give the recipe to another person', () =>
    assertFails(updateDoc(doc(db(ALICE), 'recipes', aliceId), { userId: BOB })));

  test("cannot change another person's recipe", () =>
    assertFails(updateDoc(doc(db(BOB), 'recipes', aliceId), { favorite: true })));

  test('owner can delete', () => assertSucceeds(deleteDoc(doc(db(ALICE), 'recipes', aliceId))));

  test("cannot delete another person's recipe", () =>
    assertFails(deleteDoc(doc(db(BOB), 'recipes', aliceId))));

  test('visitors cannot update or delete', async () => {
    await assertFails(updateDoc(doc(db(null), 'recipes', aliceId), { favorite: true }));
    await assertFails(deleteDoc(doc(db(null), 'recipes', aliceId)));
  });
});
