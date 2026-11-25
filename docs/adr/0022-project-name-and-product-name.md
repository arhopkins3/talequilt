# 0022. Project name and product name: TaleQuilt in code and resources, Yarnspun to users, set by configuration

- **Status:** Accepted
- **Date:** 2026-11-25
- **Deciders:** Alex Hopkins
- **Phase:** 3

## Context

Another product called TaleQuilt is preparing to launch at talequilt.com. The name is in this repository's name, its namespaces and projects, its container images, every Azure resource, the workflows and twenty-one decision records; about two hundred occurrences across sixty files. Changing all of it is a mechanical rename of the code and a rebuild of both Azure environments, because Azure resources cannot be renamed. That would cost about a day now and more each month, and it would buy nothing a user can see.

What a user sees is a different matter. The web app's title and heading, the PDF's metadata when Phase 7 produces it, the sign-in screens in Phase 5, a custom domain, and anything published about the app all carry a name to the public, and that name should not collide with someone else's product. Alex has chosen Yarnspun for the product, from the knitting idea: a yarn is a story, and a yarnspun book is one that has been made. The people who write with it are yarnspinners, which names a possible community later.

## Options considered

| Option                                                                         | For                                                                                                                                      | Against                                                                                                        | Monthly cost    |
| ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | --------------- |
| Rename everything to the new name                                              | One name everywhere                                                                                                                      | A day of mechanical change, both environments rebuilt, every record edited; repeated if the name changes again | Nothing ongoing |
| Keep TaleQuilt everywhere, including in front of users                         | No work                                                                                                                                  | A public collision with another product; a trademark and domain problem waiting                                | Nothing         |
| Keep TaleQuilt as the project name; make the public name a configuration value | Small change; the rule that a swap is configuration (CLAUDE.md rule 7, applied to a name); a different label per environment is possible | Two names to explain, in CLAUDE.md and here                                                                    | Nothing         |

## Decision

The third option. TaleQuilt is the project name and stays in the repository, the code, the images, the Azure resources, the workflows and the documents, including the records written before this one. Yarnspun is the product name and is the only name a user sees. It lives in one place on each side: the web app reads `VITE_PRODUCT_NAME` at build time, with `src/web/.env` holding the default and the Deploy workflow passing an environment's optional `PRODUCT_NAME` variable; the API reads `Product:Name` from configuration, with the default in `appsettings.json`, and uses it today for the OpenAPI document's title and later for the PDF's metadata. Nothing else in the code knows the product name. Yarnspinners is reserved for the community idea, which is a candidate later phase with its own brief, `docs/phases/candidate-yarnspinners.md`, and is not built by this decision.

## Consequences

A rename of the product is a variable change and a deploy, not a pull request. The portfolio page and anything else published say Yarnspun and may say the project is called TaleQuilt, since the repository is public and the name is visible to anyone who reads the code. Two checks remain Alex's to do before the name is used anywhere permanent: the `.com` and `.co.uk` domains for Yarnspun and Yarnspinners, and the UK Intellectual Property Office register in classes 9, 41 and 42; both words are plain English compounds, so a weak trademark is the likely answer and the names are worth more as a consistent brand than as a registration. The static forbidden page under Static Web Apps cannot read a build variable and names no product. CLAUDE.md rule 9 (text rights) is unchanged by this decision and is the first rule a community phase would have to generalise. Revisit this decision if the product name changes again, if a second product appears, or if the community phase is approved.

## At company scale

A naming authority (often legal and brand together) owns product names and checks them against trademark and domain registers before a repository is created; engineering names are deliberately dull and never leak to users. Display names live in a localisation layer, not in configuration, because they differ by market as well as by product, and a rename is a content change signed off by brand rather than a deploy. Internal names appear in resource tags and cost reports, and a mapping from product to internal names is kept where support and finance can read it.
