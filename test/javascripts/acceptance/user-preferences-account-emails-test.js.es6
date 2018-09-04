import { acceptance } from "helpers/qunit-helpers"

acceptance("Mozilla IAM - User Preferences Account Emails", {
  loggedIn: true
});

const responseWithSecondary = secondaryEmails => {
  return [
    200,
    { "Content-Type": "application/json" },
    {
      id: 1,
      username: "eviltrout",
      email: "eviltrout@example.com",
      secondary_emails: secondaryEmails
    }
  ];
};

QUnit.test("viewing self without secondary emails", async assert => {
  server.get("/u/eviltrout.json", () => {
    return responseWithSecondary([])
  })

  await visit("/u/eviltrout/preferences/account")

  assert.equal(
    find(".pref-mozilla-iam-primary-email .value").text().trim(),
    "robin.ward@example.com",
    "it should display the primary email"
  )

  assert.equal(
    find(".pref-mozilla-iam-secondary-emails .value").text().trim(),
    "No secondary addresses",
    "it should not display secondary emails"
  )
})

// QUnit.test("viewing self with multiple secondary emails", async assert => {
//   // prettier-ignore
//   server.get("/admin/users/1.json", () => { // eslint-disable-line no-undef
//     return responseWithSecondary([
//       "eviltrout1@example.com",
//       "eviltrout2@example.com",
//     ]);
//   });
//
//   await visit("/admin/users/1/eviltrout");
//
//   assert.equal(
//     find(".display-row.email .value a").text(),
//     "eviltrout@example.com",
//     "it should display the user's primary email"
//   );
//
//   assertMultipleSecondary(assert);
// });
//
// QUnit.test("viewing another user with no secondary email", async assert => {
//   await visit("/admin/users/1234/regular");
//   await click(`.display-row.secondary-emails button`);
//
//   assertNoSecondary(assert);
// });
//
// QUnit.test("viewing another account with secondary emails", async assert => {
//   // prettier-ignore
//   server.get("/u/regular/emails.json", () => { // eslint-disable-line no-undef
//     return [
//       200,
//       { "Content-Type": "application/json" },
//       {
//         email: "eviltrout@example.com",
//         secondary_emails: ["eviltrout1@example.com", "eviltrout2@example.com"]
//       }
//     ];
//   });
//
//   await visit("/admin/users/1234/regular");
//   await click(`.display-row.secondary-emails button`);
//
//   assertMultipleSecondary(assert);
// });
