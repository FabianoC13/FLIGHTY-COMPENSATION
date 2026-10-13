# EU261 claim companies: claim flows, signed documents, fees and legal basis

*Research date: 2026-10-12. Sources are cited inline. Anything marked **[inferred]** is my own reading, not something a source states. Anything marked **[unverified]** comes only from a third-party or secondary source. Company websites change often (fees especially), so re-check before relying on any figure.*

## 0. Scope and coverage

| Company | Status / HQ | Depth of research |
|---|---|---|
| AirHelp | Berlin/Gdańsk; market leader | Primary sources: T&Cs, price list, help pages |
| Flightright | Potsdam/Berlin, DE; registered legal-services provider under the German RDG | Primary source: full T&Cs (DE + EN) |
| Skycop | Vilnius, LT | Primary sources: T&Cs, price list |
| AirAdvisor | Air Advisor sp. z o.o. (PL) / AirAdvisor International Inc. (US) | Primary sources: T&Cs, comparison pages |
| Compensair | Compensair Pte. Ltd., Singapore | Primary sources: T&Cs, payment policy |
| ClaimCompass | **Acquired by AirHelp** (announced Dec 2024). claimcompass.eu now 301-redirects to airhelp.com | Status only |
| Refund.me | Website unreachable during research (connection reset) | Secondary sources only |

- ClaimCompass acquisition: [TravelDailyNews](https://www.traveldailynews.com/aviation/airhelp-acquires-claimcompass), [Capital.bg](https://www.capital.bg/en/business/2025/01/30/4735972_berlin-based_airhelp_acquires_bulgarias_claimcompass/). The redirect was observed directly when fetching `claimcompass.eu/terms-and-conditions`.
- Refund.me: a 25% contingent fee (+VAT in UK reporting), per [Wikipedia](https://en.wikipedia.org/wiki/Refund.me) and older press **[unverified, possibly outdated]**. It is excluded from the detailed comparison below.

---

## 1. AirHelp

### 1.1 Claim flow
Sources: [AirHelp blog, "How to use AirHelp"](https://www.airhelp.com/en/blog/how-to-use-airhelp-to-claim-flight-compensation/), [Our fees](https://www.airhelp.com/en-int/our-fees)

1. **Eligibility check (no account needed):** departure and final destination airports, whether the trip was direct or had connections, travel date, airline, flight number, and disruption type (delayed / cancelled / denied boarding). For delays, the arrival delay band: ≥3h, <3h, or never arrived.
2. **Personal details:** first name, last name and e-mail, which creates the account. Then the **booking reference (PNR)**, with a help dropdown showing where to find it.
3. **Result:** the estimated compensation is shown.
4. **Signature:** the passenger **draws a signature in a box** to sign the assignment agreement.
5. **Documents:** upload a travel document (booking confirmation / boarding pass) and **ID**. Free-text description of what happened. A question on whether the passenger has already contacted the airline.
6. Claim ID is issued and tracked in the AirHelp app or dashboard.
7. Later, on request: **POA / Conditional Fee Agreement** for court, a **boarding pass** (some airlines and courts require it; otherwise a boarding certificate from the airline), and proof of address in some jurisdictions. ([Documents & privacy help](https://www.airhelp.co.uk/help/documents-and-privacy/))

### 1.2 Documents signed and how
Source: [AirHelp General Terms](https://www.airhelp.com/en/ota/common/terms/), [Documents & privacy](https://www.airhelp.co.uk/help/documents-and-privacy/)

- **Terms acceptance** (checkbox / click-through) **[inferred from standard flow]**.
- **Assignment Agreement:** "the standard document, in electronic or other format, requested by AirHelp on a case-by-case basis", which makes AirHelp the owner of the claim. Local names vary: assignment contract (EU), proxy (Brazil), authority document (France, Spain).
- **Authority Document / Power of Attorney:** the "exceptional" alternative, used where assignment is not possible. AirHelp tells the customer in writing which one applies before signing.
- **POA / CFA for litigation:** signed later, via a HelloSign link or printed, signed and uploaded. Some courts need a **handwritten, scanned signature**. Documents must be complete and legible, with no edits.
- **Signature mechanics:** the "AirHelp Signature" is drawn "by the Customer's own hand on a touchscreen or equivalent input device". It is logged with **timestamp, IP address, device fingerprint and a Certificate of Completion**. This is an audit trail typical of a *simple/advanced-like* e-signature **[inferred classification]**.
- **Fellow passengers / minors:** a customer acting for others must first hold a **power of attorney** from them and show proof on request. For **minors**, the customer must provide the child's full details plus the **names and signatures of the custodians / legal guardians**. The customer also warrants that fellow passengers consented to sharing their data.
- An unofficial copy of an older AirHelp assignment form includes a **fallback POA if the assignment is declared invalid** ([Scribd copy](https://www.scribd.com/document/374157227/assignment-form-en-pdf) **[unverified]**).

### 1.3 Fees
Sources: [Price list](https://airhelp.com/en/price-list/), [Our fees](https://www.airhelp.com/en-int/our-fees)

- **Service fee: 35% of compensation, VAT included.**
- **Legal Action Fee: +15% (VAT included)**, charged only if legal action was needed. AirHelp says this happens in about 3% of cases. Maximum total is 50%. AirHelp pays court and legal expenses.
- Denmark uses fixed amounts (about 35%). Brazil has a separate list. AirHelp+ members pay 0%.
- Goodwill claims carry a fee of US$29.99. No minimum fee is stated for EU261 claims.

### 1.4 Payout
- **International bank transfer** through a third-party payment provider. AirHelp adds no charge, but the passenger's own bank may.
- EU261 payouts are in EUR.
- Payouts go **only to the main claimant's bank account** (a data-protection measure). ([Documents & privacy](https://www.airhelp.co.uk/help/documents-and-privacy/))
- One user report mentions a cheque option **[unverified]**.
- No fixed timing is published.

### 1.5 If the airline refuses
AirHelp may start "Legal Action" when the airline does not pay within a reasonable time or is unlikely to respond. Legal Action expressly includes filing with a **national enforcement body (NEB)**, the German Schlichtungsstelle (söp), the Federal Office of Justice arbitration body, or a court through partner lawyers. ([Terms](https://www.airhelp.com/en/ota/common/terms/))

---

## 2. Flightright

### 2.1 Claim flow
Sources: [Flightright AGB (DE)](https://www.flightright.de/agb), [Terms (EN)](https://www.flightright.com/terms-and-conditions), secondary: [thetraveler.org](https://www.thetraveler.org/flightright-step-by-step-how-to-file-a-compensation-claim/)

1. **"Claimcheck"**: flight and disruption details, with an online calculator. The calculator result is expressly "not a binding offer".
2. **Order process (Bestellprozess)**: flight data, **postal address, phone, e-mail**, and any payments already received from the airline. A **summary screen** lets the customer review and correct the data before submitting.
3. The customer clicks the **order button**. This is a binding offer to conclude a paid agency contract (*entgeltlicher Geschäftsbesorgungsvertrag*). Flightright accepts by e-mail or simply by asserting the claim against the airline.
4. **Upload boarding pass and sign a digital contract** (reviewer accounts **[unverified]**).
5. A customer portal account is created automatically.
6. **"Upon request"**: the customer signs a separate **deed of assignment / confirmation of assignment or POA document and sends the ORIGINAL** (wet ink) to Flightright. This is typically needed for court. ([AGB §2.1](https://www.flightright.de/agb))

### 2.2 Documents signed
- **AGB acceptance** at order (button). The AGB itself contains the assignment declaration: the customer "assigns the claim in trust (*treuhänderisch*) to us **at our choice**, and at the same time authorizes us to enforce it under your name" (**Assignment Process**). Alternatively, the customer authorizes Flightright to enforce the claim in the customer's name without assignment (**Power-of-Attorney Process**). ([AGB §1.3](https://www.flightright.de/agb))
- The customer also **assigns their cost-reimbursement claims** (§ 13e RDG / RVG costs against the airline) "in lieu of performance" (§3.3).
- Settlement authority: Flightright may settle without consulting the customer if the payout is not materially reduced. It may reject offers below **80%** of the claim or voucher-only offers (§7).
- Exclusivity: the customer may not instruct other providers, the söp or consumer bodies, or sue independently (§5).
- Governing law is German, including for the assignment contract. Mandatory consumer law of the customer's country of residence also applies (§13).
- **Minors**: not addressed in the AGB. Payments meant for co-travellers must be forwarded pro rata by the recipient (§4.3).

### 2.3 Fees
- The percentage is **"agreed in the order process"**, **plus statutory VAT** (19% DE). It is higher when contract lawyers are engaged (§3.4).
- Published ranges from secondary sources: **20–30% + VAT**, with a **+14% + VAT** surcharge when lawyers are involved. A typical standard rate of about 27–28% + VAT (≈33% gross) is reported. [airadvisor comparison](https://airadvisor.com/en/compare/flightright-vs-airadvisor), [thetraveler.org](https://www.thetraveler.org/most-travelers-miss-this-about-flightrights-fees/) **[unverified]**.
- Interest on the claim goes 100% to Flightright. Interest earned on the escrow account is kept by Flightright, and the customer waives it (§3.4.2, §4.1).
- No win, no fee, including when lawyers were engaged.

### 2.4 Payout
- Funds are held on an **escrow account (Anderkonto)** and paid by **SEPA transfer** to the account the customer provides. **PayPal** may be offered. Non-SEPA fees are borne by the customer.
- Payment is made once all documents needed for settlement are available (§4).

### 2.5 If the airline refuses
- First an out-of-court demand, then a **court dunning procedure (Mahnverfahren)**, then a **contract lawyer** mandated in Flightright's own name and at its own cost risk (Assignment Process). In the POA Process, Flightright instructs the lawyer in the customer's name. Flightright bears all costs if unsuccessful (§6).
- As an RDG provider, Flightright **cannot represent customers before ordinary civil courts** itself (§6.1).

---

## 3. Skycop

### 3.1 Claim flow
Sources: [Skycop T&C](https://www.skycop.com/terms-and-conditions/), secondary: [thetraveler.org](https://www.thetraveler.org/what-to-know-about-skycop-before-filing-a-compensation-claim/)

1. Flight data is submitted via the website, the app, e-mail or other tools (T&C 2.1).
2. Eligibility assessment, which is "not a binding statement" (2.2).
3. Personal and passenger data. The passenger **e-signs the agreement / assignment** online; one reviewer reports this took about 15 minutes.
4. Documents: "**copies of identity documents, boarding pass, delay notification**" (4.3).
5. Skycop files with the operating carrier, then may start legal proceedings (2.3–2.4).

### 3.2 Documents signed
- **T&C = the Agreement**, under which "the Client assigns to Skycop full ownership and legal title to his (her) monetary claim" (definitions, 1.1).
- **Signature: an online authentication service for *advanced* electronic signatures** meeting **eIDAS Art. 26**. No printing or mailing is needed (1.2).
- The client confirms **capacity and the right to sign on behalf of another person, e.g. a child** (1.3).
- The client warrants that the claim was **not previously assigned** and that no dispute is pending (1.4).
- For litigation, the claim is **re-assigned back to the client**, who then signs an agreement with the legal representative and must supply POA evidence when asked (2.5).
- Withdrawal: 14 days for consumers (5.2).

### 3.3 Fees
Source: [Skycop price list](https://www.skycop.com/price-list/), version dated 2024-05-01, VAT included

| Compensation | Standard (44%) | With legal action (50%) |
|---|---|---|
| €250 | €110 | €125 |
| €400 | €176 | €200 |
| €600 | €264 | €300 |

- Skycop may raise the share further to cover court costs, translation and similar. VAT follows Lithuanian law (3.6).
- If the airline pays the client directly, the client must pay Skycop's share within **10 days** (4.4).

### 3.4 Payout
- **Bank transfer only** (3.8). International bank fees are deducted from the client's share.
- Where one parent is paid for children, the recipient must settle with the others (3.9).
- Reviews report very long payout delays **[unverified]**.

### 3.5 If the airline refuses
Legal proceedings at Skycop's discretion (2.4), via re-assignment and a legal representative. The client has no costs if the claim fails (2.7).

---

## 4. AirAdvisor

### 4.1 Claim flow
Source: [AirAdvisor terms (en-us)](https://airadvisor.com/en-us/terms), [comparison page](https://airadvisor.com/en/compare/airhelp-vs-airadvisor)

1. Flight details entered, then a free eligibility check (about 3 min).
2. Registration and claim submission. "Registering or submitting is confirmation of execution of a contract."
3. **Assignment document e-signed at the end of the application** (T&C 1.5).
4. Bank details are entered later in the member account.

### 4.2 Documents signed
- **Assignment** (1.5): "a document authorizing Contractor to represent Member's interests in matters before third parties". It is "a digital document that is signed by Member with an electronic signature at the end of the process".
- A sample AirAdvisor assignment form (2025, Ryanair flight) names AirAdvisor as **assignee and holder of exclusive rights**. It bars the client from accepting direct payment and includes a **fallback POA covering the client and accompanying passengers** ([JustAnswer thread](https://www.justanswer.de/anwalt/sohqp-sehr-geehrte-damen-herren.html) **[unverified]**).
- Third-party data: the member warrants they have "all necessary authorities" (7.2). No specific process for minors is described.
- The member must "issue, sign, attest and furnish all necessary documents" a court requests, **e.g. a notarized POA** (2.5).
- Withdrawal: 14 days, unless a claim has already been filed (6.2).

### 4.3 Fees
VAT is included in all rates (T&C 5.2).

| Claim type | Fee |
|---|---|
| Flight disruption | **30%** |
| Baggage / expenses | 40% |
| With a lawyer | **50%** |

- **Minimum fee:** below a threshold (e.g. US$250 collected), a fixed fee applies (e.g. US$100) (5.3).
- Some AirAdvisor pages state 35% instead **[conflicting sources]**.

### 4.4 Payout
- To the bank details and method chosen in the member account, **within 30 days of receiving correct bank details** (3.4).
- Typical collection time is 1–3 months, per AirAdvisor's own figure.

### 4.5 If the airline refuses
"Legal collection process", possibly court, through partner lawyers at AirAdvisor's discretion (2.5).

---

## 5. Compensair

Sources: [Compensair T&C](https://www.compensair.com/en/terms-and-conditions/), [Payment policy](https://www.compensair.com/en/payment-policy/)

### 5.1 Claim flow
1. Online "Application" form containing the client's personal data, also available as an embeddable partner iframe widget (1.1, 1.10).
2. The client accepts the T&C, which also binds them to the Privacy, Cookie and Payment policies (2.1).
3. Documents are supplied as needed. Further identity verification may be required by the licensed payment provider before release of funds.

### 5.2 Documents signed / legal construction
- **No assignment.** The client **"irrevocably authorises Compensair and its Partners to recover the Compensation, receive it into a Compensair bank account and deduct the Service Fee"**. Compensair may create a **virtual account in the client's name** via third parties (2.7). This is a mandate/POA model.
- The client represents **capacity and authority for any co-claimants** named in the application (2.3).
- Exclusivity: no other claims, ADR or assignment without written consent. The client must forward all airline correspondence (2.7–2.8).
- Withdrawal: **7 days** (2.5). Singapore law and courts apply, plus GDPR for EU clients (6.3–6.4).
- This is notably weaker consumer protection than EU competitors **[inferred]**: EU consumer law normally gives 14 days and mandatory home-court rules.

### 5.3 Fees
- **35%** service fee, plus **+10%** if extra legal expenses arise. VAT is not mentioned.
- If the client receives a payment directly, they must notify Compensair within **3 days** and pay the fee.

### 5.4 Payout
- **Bank transfer** (IBAN/SWIFT). The client bears bank fees and receives no interest.
- If the transfer is not received within 3 months, the client must say so; otherwise it is deemed complete.

### 5.5 If the airline refuses
- Compensair decides, together with legal partners, whether to sue, with **7 days' notice** to the client. A contracted legal representative then acts.
- If the client withdraws after litigation starts, they must reimburse legal costs incurred (3.6–3.8).

---

## 6. Comparison summary

| | AirHelp | Flightright | Skycop | AirAdvisor | Compensair |
|---|---|---|---|---|---|
| Legal model | Assignment (POA exceptionally) | Fiduciary assignment **or** POA, at provider's choice | Full assignment; re-assigned for court | Assignment + fallback POA | Irrevocable mandate (no assignment) |
| Signing | Drawn on screen + audit trail; HelloSign/wet ink for court | Click-through order; original wet-ink deed on request | Advanced e-signature (eIDAS Art. 26) | E-signature at end of form; notarized POA if court requires | T&C acceptance |
| Minors | Guardian names + signatures | Not addressed | Signer confirms right to sign for child | Warranty of authority | Warranty of authority |
| Base fee | 35% incl. VAT | ~20–30% + VAT (set in order flow) | 44% incl. VAT | 30% incl. VAT | 35% |
| Legal surcharge | +15% (max 50%) | ~+14% + VAT | to 50% | to 50% | +10% |
| Payout | Bank transfer (EUR) | SEPA from escrow; PayPal possible | Bank transfer | Bank / chosen method, ≤30 days | Bank transfer |
| Withdrawal | 14 days (EU law) | 14 days | 14 days | 14 days | 7 days |

---

## 7. Legal basis

### 7.1 Are e-signatures enough for an assignment or POA?
- **eIDAS (Reg. (EU) 910/2014, as amended by Reg. (EU) 2024/1183), Art. 25(1):** an electronic signature "shall not be denied legal effect and admissibility as evidence in legal proceedings solely on the grounds that it is in an electronic form". Only a **qualified** e-signature (QES) is *equivalent* to a handwritten one (Art. 25(2)). ([summary via DocuSign](https://www.docusign.com/products/electronic-signature/legality/germany))
- eIDAS does **not** set form requirements. Whether a simple e-signature (SES) suffices depends on whether **national law requires a specific form** for the act.
- **Germany (example jurisdiction; most claim companies use German law):**
  - **§ 398 BGB:** an assignment is a formless contract. No written form is required, so a click/SES assignment is valid ([gesetze-im-internet § 398](https://www.gesetze-im-internet.de/bgb/__398.html)).
  - **§ 167(2) BGB:** a power of attorney generally needs no form ([§ 167](https://www.gesetze-im-internet.de/bgb/__167.html)).
  - **But there are practical "original document" hooks:**
    - **§ 410 BGB:** the debtor (airline) only has to pay the assignee **against delivery of an assignment deed (Urkunde) issued by the assignor**, and may reject a reminder made without it. This does not apply if the assignor notified the debtor **in writing** ([§ 410](https://www.gesetze-im-internet.de/bgb/__410.html)).
    - **§ 174 BGB:** a unilateral act (e.g. a payment demand) by an agent can be rejected if no **original POA document** is presented ([§ 174](https://www.gesetze-im-internet.de/bgb/__174.html)).
    - **§ 80 ZPO:** in court, the litigation POA must be filed **in writing** ([§ 80 ZPO](https://www.gesetze-im-internet.de/zpo/__80.html)).
  - This explains Flightright's clause requiring the customer, "on request", to sign a separate deed and send the **original** ([AGB §2.1](https://www.flightright.de/agb)).
  - **[Inferred]** "Written form" (§ 126 BGB) can only be replaced electronically by a **QES** (§ 126a BGB). Otherwise a wet-ink original is the safe option for those specific steps.
- **Practical conclusion [inferred]:** an SES with a strong audit trail (drawn signature, timestamp, IP, device, e-mail/SMS OTP, document hash) is sufficient for the **contract, the assignment and the POA** in the out-of-court phase in most EU jurisdictions. Plan for (a) an ID copy for signature verification, (b) a QES or wet-ink original when an airline invokes § 410/§ 174 BGB-type rules or when filing in court. Skycop's AES (Art. 26) is a middle ground: stronger evidentiary value, but still not legally equivalent to a handwritten signature.

### 7.2 Minors
- **[Inferred, German law]** Under **§ 1629 BGB**, parents represent the child **jointly**; one parent acts alone only with sole custody or a delegated decision ([§ 1629](https://www.gesetze-im-internet.de/bgb/__1629.html)). Strictly, both custodial parents should therefore sign for a minor's assignment or POA. In practice, companies accept one parent's signature plus a warranty of authority (Skycop 1.3, AirAdvisor 7.2). AirHelp requires names and signatures of **custodians/guardians** ([AirHelp Terms](https://www.airhelp.com/en/ota/common/terms/)).
- Other jurisdictions have similar joint-custody rules **[not verified per country]**.

### 7.3 Can airlines refuse third-party claims or prohibit assignment?
- **CJEU C-11/23 *Eventmedia Soluciones v Air Europa*, 29 Feb 2024:**
  - Compensation rights arise directly from Reg. 261/2004.
  - **Art. 15 precludes a clause in the contract of carriage that prohibits the passenger from transferring (assigning) those rights.**
  - Airline anti-assignment clauses are therefore ineffective for EU261 claims.
  - Sources: [OJ C/2024/2579](https://eur-lex.europa.eu/eli/C/2024/2579/oj), [verbraucherrecht.at PDF](https://verbraucherrecht.at/system/files/2024-04/EuGH%20C%2011-23.pdf).
- A related case, C-173/23 (11 Apr 2024), concerns Montreal Convention baggage claims: a court is not obliged to examine *ex officio* the unfairness of an assignment ban.
- **European Commission information notice on claim agencies (9 Mar 2017):**
  - "If so requested, a **signed power of attorney together with a copy of ID or passport (for verification of signature)** should be provided by claim agencies".
  - Prices must be displayed upfront and **including all fees and taxes**.
  - No persistent telemarketing.
  - OTAs and other third parties must not pass passenger data to claim agencies without a legal basis or the passenger's permission.
  - Sources: [EC note PDF](https://transport.ec.europa.eu/document/download/604d45f0-cc92-430e-935a-ef92bd3788cb_en), [mirror](https://holidays.malaysiaairlines.com/content/dam/mas/pdf/2017-03-09-information-note-air-passenger-rights-on-claim-agencies_en.pdf).
- **Airline practice:**
  - **Ryanair** actively discourages "claims chasers" and pays compensation **directly to passengers**. UK courts upheld this practice in the *Bott & Co v Ryanair* litigation (High Court 2018 / Court of Appeal). The UK Supreme Court later ruled for Bott on the solicitors' equitable lien in [2022] UKSC 8 **[from memory, verify]**.
    - Ryanair has used an Irish jurisdiction clause against agency claims ([MSE 2016](https://www.moneysavingexpert.com/news/2016/12/ryanair-clarifies-it-will-only-push-compensation-claimants-through-irish-courts-if-claims-chashers-are-used/), [Ryanair press 2018](https://corporate.ryanair.com/nachrichten/ryanair-begrusst-urteil-des-obersten-gerichtshofs-in-london-gegen-ausgleichsjager/)).
    - A Lithuanian court held Ryanair's assignment-ban terms unfair ([BNS](https://sc.bns.lt/view/item/justice-for-air-passengers-ryanair-loses-the-battle-against-its-unfair-terms-conditions-329253), claim-firm press release **[unverified]**).
  - **easyJet:** its claim form requires that the claimant is a passenger on the booking ([easyJet EU261 form](https://www.easyjet.com/claim/en/eu261)). No specific agency policy was found **[gap]**.
  - **General:** airlines commonly demand a signed POA/assignment **plus an ID copy** before engaging ([HFW 2017](https://www.hfw.com/insights/claim-agencies-in-the-crosshairs-of-the-european-commission-april-2017/); Swiss FOCA rejects forged-looking POAs and asks for an ID copy, [BAZL info](https://www.bazl.admin.ch/dam/bazl/en/dokumente/Gut_zu_wissen/Fluggastrechte/Info-ClaimAgencies.pdf.download.pdf/Info-ClaimAgencies.pdf)). AirHelp itself says it requests ID only because some airlines need it "to validate the authenticity of the Assignment Form" ([AirHelp FAQ](https://www.airhelp.com/en/faq/documents-and-privacy)).
  - **Risk [inferred]:** an airline may pay the passenger directly despite the assignment. All competitors therefore include a clause obliging the passenger to forward the money or pay the fee (Skycop 10 days, Compensair 3 days, Flightright invoice).
- **EU261 reform:**
  - A provisional agreement was reached around 15 June 2026. It is reported to keep the 3h threshold and €250/400/600, and to require airlines to provide claim forms or pre-filled documents.
  - Claim agencies reportedly can still receive payments.
  - Formal adoption is pending; the text has not been verified.
  - Sources: [CAPA](https://centreforaviation.com/news/eu-reaches-agreement-on-eu261-passenger-rights-regulation-revisions-1362892), [CMS](https://cms.law/en/bel/legal-updates/new-european-regulation-on-air-passenger-rights-what-impact-for-the-air-transport-sector).

### 7.4 GDPR notes
**[Mostly inferred from GDPR text and competitor practice]**

- **Lawful basis:** Art. 6(1)(b) (contract performance) for the claim data. Art. 6(1)(f) or 6(1)(c) for disclosure to airlines, NEBs, courts and lawyers. Competitors make the lawyer disclosure explicit (AirHelp, Flightright §6, Compensair 3.7).
- **ID documents:** not special-category data, but high-risk. Collect them **only when required** (minimisation, Art. 5(1)(c)): just-in-time on airline request or for litigation, or redact the ID number and photo where only signature verification is needed. Keep a short retention period after case closure. Some member states restrict ID-number processing (Art. 87).
- **Fellow passengers and children:**
  - The lead claimant supplies other people's data. Each adult co-passenger should ideally sign themselves (cleanest legal basis, and an airline/§ 174 BGB-proof signature).
  - Otherwise require a warranty of authority plus a mandate from them, and send them an Art. 14 information notice.
  - Children's data: the parent/guardian signs. Do not use children's data for marketing.
- **Processors and transfers:** the e-signature vendor, payment provider and OCR/ID vendor need Art. 28 DPAs. Transfers outside the EU need Chapter V safeguards (cf. Compensair's Singapore structure).
- **Payout data:** pay only to the claimant's own account, or to an account the claimant designates in writing for others (AirHelp policy).
- **Marketing:** the 2017 EC notice and the ePrivacy Directive Art. 13 require prior consent. Keep marketing consent as a separate, unticked checkbox.

---

## 8. Recommended flow for our app

*This section is a design recommendation **[inferred]**, based on the patterns above. Have it reviewed by a lawyer in the jurisdiction whose law governs the contract (Germany is the common choice for enforceability under §§ 398/410 BGB and RDG registration).*

### 8.1 Steps
1. **Flight check (no account):** flight number + date, or boarding-pass scan / booking import. Then itinerary and connections, disruption type, arrival delay band, and whether the passenger already claimed or got paid. Show the eligibility result and the compensation amount **with the net payout after fees (VAT included)**, per the EC 2017 notice.
2. **Account:** e-mail + OTP verification.
3. **Passengers on the booking:** for each person, the name exactly as on the booking, date of birth (to detect minors), e-mail if 16+ / adult, and the relationship to the lead claimant.
4. **Booking proof:** PNR (mandatory) plus an upload of the booking confirmation or e-ticket. Boarding pass is optional at intake, requested if available. Delay evidence (screenshots, airline e-mails) is optional.
5. **Contact & address:** postal address, needed for court filings and RDG/invoice requirements.
6. **Review screen:** all data editable, as in Flightright §2.2.
7. **Sign (per passenger):**
   - Accept the T&C and fee agreement via a checkbox and an explicit button such as "Order with obligation to pay on success".
   - Then a **drawn signature or typed name plus OTP** on the Assignment and POA PDF, with an audit trail (timestamp, IP, device, e-mail/SMS OTP, document SHA-256 hash, completion certificate).
   - Each **adult** co-passenger receives their own signing link.
   - For **minors**, the parent/guardian(s) sign. Both parents sign unless the signer confirms sole custody, which needs a declaration and evidence on request.
8. **ID (just-in-time):** request a photo of ID only when an airline, NEB or court requests it, or for litigation. Optionally collect it upfront for low-cost carriers known to demand it **[verify per airline]**. Allow redaction of the ID number and photo.
9. **Payout details:** IBAN of the claimant (or the guardian for a minor), with a confirmation-of-payee check where available. Optionally PayPal/Wise.
10. **Status tracking:** timeline (submitted, airline notified, response, NEB/ADR, lawyer/court, paid). Push and e-mail notifications. Upload slots for requests such as a wet-ink original or QES.
11. **Escalation:** after the airline refuses or 6–8 weeks of silence, the next step is NEB/ADR (e.g. söp / Schlichtungsstelle Luftverkehr BfJ in DE), then a partner lawyer / court. Notify the user beforehand (cf. Compensair's 7-day notice). Request a QES or wet-ink court POA only at this point.
12. **Payout:** pay from an escrow/client-money account within a stated number of days (e.g. ≤14) of receipt, with a statement showing gross, fee, VAT and net.

### 8.2 Documents to sign in-app and their key clauses

**A. Terms of Service & Fee Agreement (Geschäftsbesorgungsvertrag)**, accepted by checkbox and button

| Clause | Content |
|---|---|
| Parties | Parties, service description (out-of-court enforcement of EU261 / UK261 claims, and related refunds if offered) |
| Success fee | **X% incl. VAT** and an optional **legal-action surcharge Y%**, both shown before signing. Any minimum fee stated. No fee if no success. Who bears legal costs (we do). |
| Fee base | Compensation actually recovered. Vouchers are valued at cash value or rejected. Interest (who keeps it). |
| Direct payment by airline | The customer must notify us within N days and pay the fee (all competitors have this). |
| Cooperation duties | Truthful data, forward airline correspondence, no parallel claims, no direct settlement. |
| Settlement authority | E.g. accept if ≥ 80–90% of the claim; never vouchers without consent (cf. Flightright §7). |
| Escalation | Right to escalate (NEB/ADR, lawyer, court) with prior notice. |
| Withdrawal | **14-day withdrawal right** (Consumer Rights Directive) plus a request to start immediately, with the model withdrawal form. Termination and its fee consequences. |
| Payout | Payout method, timing and currency. Bank fees for non-SEPA payouts. |
| Law & data | Governing law plus mandatory consumer law of the customer's residence. Link to the privacy notice. |

**B. Assignment of Claim (Abtretungsvereinbarung)**, one per passenger, signed by the passenger or guardian

| Clause | Content |
|---|---|
| Identification | Assignor (passenger) and assignee (company). Exact claim: flight number, date, route, PNR, legal basis (Reg. 261/2004 Art. 7, plus refund under Art. 8 if in scope), and ancillary claims (interest, costs). |
| Assignment | **Fiduciary assignment** (treuhänderisch). The assignee enforces in its own name and pays the net amount to the assignor. Acceptance of the assignment by the assignee. |
| Warranties | Claim not previously assigned, pledged or settled. No other agency or lawyer instructed. |
| Notice to airline | The assignor authorizes the assignee to notify the airline. The assignee may present this deed as the **Abtretungsurkunde** (§ 410 BGB). The assignor undertakes to sign a wet-ink or QES version on request. |
| Re-assignment | Re-assignment to the passenger if litigation in the passenger's name becomes necessary or the agreement terminates (cf. Skycop 2.5). |
| Fallback POA | **If the assignment is invalid or not accepted** by a court or airline, it is treated as a power of attorney (cf. AirHelp/AirAdvisor forms). |
| Reference | Reference to Reg. 261/2004 Art. 15 and CJEU C-11/23, so that airline non-assignment clauses are ineffective. |

**C. Power of Attorney / Mandate (Vollmacht)**, one per passenger; can be combined with B on one signed page but kept as a separate section

| Clause | Content |
|---|---|
| Authority | Authority to act for the passenger towards the airline, NEBs, ADR bodies, and to receive payments. |
| Information requests | Authority to request booking and flight information and correspondence from the airline/OTA, which also covers the EC 2017 data point. |
| Lawyers | Authority to appoint a partner lawyer and grant sub-authority (Untervollmacht). Litigation POA language for § 80 ZPO, to be re-signed in wet ink or QES if the court requires it. |
| Payment | Authority to receive payment into the company's client account and deduct the agreed fee. |
| Duration | Valid until the claim is closed. Revocable per the T&C (not "irrevocable" for consumers **[inferred risk of unfairness]**). |
| Verification | Signature verification: the signer agrees an ID copy may be shared with the airline/authority **only for signature verification** on request. |

**D. Guardian Declaration (for each minor)**, signed by the parent(s)/guardian(s)

| Clause | Content |
|---|---|
| Identification | Child's name and date of birth. Signer's name and relationship. |
| Custody | Declaration of joint vs. sole custody. If joint: either both parents sign, or the signer declares the other parent's consent (with a co-signing link offered). |
| Authority | The signer signs B and C on the child's behalf. |
| Payout | Payout to the guardian's account for the child's benefit. |
| Evidence | Undertaking to provide a birth certificate or custody evidence on request. |

**E. Co-passenger authority (only if an adult cannot sign themselves)**
- The lead claimant's warranty of authority and an indemnity.
- Each adult co-passenger should still preferably receive their own signing link. A signature from the actual passenger is what the EC 2017 notice and airlines expect.

**F. Privacy notice acknowledgement + separate optional marketing consent**
- The privacy notice is shown and acknowledged (it is not "consent" for claim processing).
- Recipients: airline, NEB/ADR, lawyers, courts, payment provider, e-signature vendor.
- Retention periods. ID-document handling.
- Marketing consent as an **unticked** separate checkbox.

**E-signature implementation [inferred]:**
- A drawn or typed SES with e-mail/SMS OTP binding, a document hash, and an audit certificate stored with the signed PDF.
- An upgrade path to QES (e.g. an eIDAS-qualified trust service provider) or a printable wet-ink pack, used only on demand (court filings, airlines invoking § 410/§ 174 BGB).
