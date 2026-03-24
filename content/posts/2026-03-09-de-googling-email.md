+++
title = 'De-Googling: Email, the hardest change first'
date = 2026-03-09T10:00:00Z
draft = true
tags = ['privacy', 'de-googling', 'proton', 'email']
+++

In my [previous post on de-googling](/posts/2026-03-08-de-googling-why-your-data-matters/), I explained what motivated me to start down this road in the first place. Next, we'll cover the hardest part: email.

## Why email first

I started with one of the hardest things to change: email. It's hard because email is tied to everything. Logins, contacts, newsletters, receipts, two-factor recovery. Your email address is both great (your friends and family know how to reach you) and terrible (you've signed up to far too many newsletters over the years to even count).

Migrating means updating your email on dozens of accounts across different services. Some make it easy, a quick change in settings. Others require logging a support ticket and waiting days. A few won't let you change your email at all, you just have to create a new account and start over losing any history in the process.

But it's also an opportunity. Moving to a new address is a chance to cut the noise and get back to a focused inbox. You don't have to carry over every subscription and notification. You sign up to the sources you actually want and let the rest die on the old address. After years of accumulation, starting with a clean slate was one of the more satisfying parts of the whole process.

## Choosing a provider

I looked at a few options. [Proton](https://proton.me/) was the most obvious candidate for email, but I also spent time with [HEY](https://www.hey.com/). Ultimately Proton had the stronger reputation for privacy, particularly around its use of [zero-access encryption](https://proton.me/blog/zero-access-encryption). Even Proton can't read your email at rest, which was the kind of trust model I was after.

Beyond the encryption, I needed a provider that supported practical email features for someone running a custom domain:

- **Custom DNS** for routing mail to my own domain
- **Catch-all addresses** so I could hand out unique addresses per service and track who leaks or sells them
- **Advanced filtering** via [Sieve](https://proton.me/support/sieve-advanced-custom-filters), which gives proper programmatic control over mail sorting rather than the basic label-and-archive rules most providers offer

Proton delivered on all of these. The Sieve support in particular was a pleasant surprise, it's a well-established standard and far more capable than Gmail's filters ever were.

## Owning your email domain

Moving email to my own domain was one of the more important steps. With a custom domain, the provider becomes interchangeable. If Proton ever changes direction, raises prices unreasonably, or compromises on privacy, I can move my email to another provider without changing my address. Everyone who has my email address doesn't need to know or care where it's actually hosted.

This is the kind of control you give up when your email is `yourname@gmail.com`. Your address is tied to Google's infrastructure, and leaving means telling everyone you've moved.

## What's next

Email was the first step, but there's more to unwind. In future posts I'll cover migrating away from Google's other services:

- **Cloud storage and documents** - replacing Google Drive and Docs
- **Photos** - finding a home for years of photos outside Google Photos
- **Password management** - [moving from 1Password to Proton Pass](/posts/2026-03-07-proton-pass-migration/)
- **Browser** - life beyond Chrome

Each of these has its own trade-offs and rough edges. The goal isn't to pretend it's all seamless, it's to document what worked, what didn't, and where the compromises are.
