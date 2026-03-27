[home](https://www.pencilandpaper.io/)

[Contact Us](https://www.pencilandpaper.io/contact-us)

![close](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65e6e8739a35afe6e1583c3a_close%20(1).webp)

# Mobile Filter UX Design Patterns & Best Practices

July 15, 2024

![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/68cc8e9ebce12671fa1aa158_fanny-vassilatos02.webp)

Fanny Vassilatos

![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/68cc8e8c9183017ec362383c_ceara-crawshaw02.webp)

Ceara Crawshaw

![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/674f2ac05db7b2a97b360363_hero-article-mobile-filters.webp)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/665e2f9a8cc6f2fefef3de44_blob-big-s.svg)

[Distinguishing enterprise vs consumer for mobile filters](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#distinguishing-enterprise-vs-consumer-for-mobile-filters)

[Different goals](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#different-goals)

[Relationship to labels](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#relationship-to-labels)

[Prioritizing filters](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#prioritizing-filters)

[Things to consider when designing mobile filter UX](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#things-to-consider-when-designing-mobile-filter-ux)

[Typical problems for mobile filters](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#typical-problems-for-mobile-filters)

[Layout & Positioning is key on mobile](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#layout-and-positioning-is-key-on-mobile)

[How & When to fetch](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#how-and-when-to-fetch)

[Live-Filtering](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#live-filtering)

[Per-filter](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#per-filter)

[Batch filtering](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#batch-filtering)

[UX Patterns you can use](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#ux-patterns-you-can-use)

[Progressive disclosure](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#progressive-disclosure)

[Be selective](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#be-selective-2)

[Be selective](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#be-selective)

[Offer “quick filters”](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#offer-quick-filters)

[Accelerate selections](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#accelerate-selections)

[Don’t be afraid of big target areas](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#dont-be-afraid-of-big-target-areas)

[Allow users to save presets](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#allow-users-to-save-presets)

[Embrace the OS](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#embrace-the-os)

[Wrapping up](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#wrapping-up)

While doing some research for this piece, I was barely surprised to see that the first page of results is exclusively about e-commerce search and filtering. Lots of results are from Dribbble and even Pinterest… And that’s even when I write “enterprise” in my query. Have I not been using the right word? Please enlighten me. You might blame my Google algorithm, but I’m an enterprise UX designer and have been googling enterprise UX stuff for _years_! Luckily, that’s why we’re here.

Our original [Enterprise Filtering](https://pencilandpaper.io/articles/ux-pattern-analysis-enterprise-filtering/) piece had a great impact, and a lot of the questions around it were about mobile use cases. Ask and you shall receive!

## Distinguishing enterprise vs consumer for mobile filters

### Different goals

There’s a lot to unpack here. First off, enterprise and consumer products have very different goals. In the context of filtering, consumer filters want you to buy. Regardless of what you search, they're incentivized (and do!) find ways to show you something even if there's no matches. It could be presented as "Did you mean \[this search term\] instead?" or "Similar to \[search term\]".

However, for enterprise search and filtering behaviour, "no results" is a valid thing to display. Users might even be hitting up those search and filter functions to validate their assumptions and expectations, or as a key method of keeping an eye on things in their workflow. A good example of this is when users set their filters to "assigned to me" and "hide done". Sound familiar? On that note, notice that filters in enterprise aren't necessarily always triggered by search terms either. They can be just another way to refine what you're pulling from the database by default.

### Relationship to labels

Enterprise and consumer apps also deal differently with labels. Consumer apps get to create labels and standardize their length.

Enterprise, on the other hand, has to deal with unpredictable, user generated strings. (And an unpredictable _amount_ of strings at that!)

### Prioritizing filters

Enterprise also has to prioritize their content differently. Consumer apps get to curate which filters to display and in what order—again, optimized for shopping.

However, enterprise platforms have to show _aaall_ the data points in modifiable orders. (If users reorder their table columns, ideally you’d want to reflect that in the filters as well.)

🔗 Check out our in depth article on [UX patterns for data tables](https://www.pencilandpaper.io/articles/ux-pattern-analysis-enterprise-data-tables/).

## Things to consider when designing mobile filter UX

A lot of our reflection and discussion prompts for building desktop filters apply for mobile as well. [Take a look here](https://pencilandpaper.io/articles/ux-pattern-analysis-enterprise-filtering/)!

**What are your users’ mobile use cases?**

You should invest some time to research this before developing the mobile version of any enterprise feature. Enterprise tends to cater to incredibly specific workflows, and it’s very likely that the mobile version of it is even more specific.

For example, think of some kind of sales-y commerce system. Depending on their role, a user’s tasks when they’re sitting at their desk can vary greatly from what they need to update while they’re commuting between two meetings—maybe they just need to quickly update the status of an entry, or add a simple note.

Knowing these things about your users will feed directly into the definition of an appropriate mobile solution.

**Are you building in-browser or native?**

You should get familiar with your app’s environment very early on. For search and filter behaviour, that means taking inventory of which native pieces you’ll get to reuse. Will you be leveraging browser-specific elements or OS-wide stuff? Do you know if your users choose native Safari over the Chrome app? Are you optimizing for Android first? All of these decisions affect the visual experience of using your filters.

☝️ Did you know \| Quick note about browsers on iOS

All browsers on iOS are basically skins on top of Safari’s rendering engine. So as long as your app is running smoothly on native Safari, chances are you’re good on other browsers as well. There’s a little fun fact for the next chat you have with your dev team.

**How will you adapt fetching?**

If you’re building search filters for mobile, chances are you’ve already got a parallel feature running on your desktop version. Going mobile might mean you want to re-evaluate your fetching mechanism: Something that performs well on a laptop might not work as well on a smartphone. How will it perform on patchy 3G networks compared to dedicated wifi or ethernet connections? Adapting may mean thinking of how to optimize performance.

## Typical problems for mobile filters

What makes mobile filtering so hard? Filtering is hard on mobile because with such a tiny screen, there’s a lot of scrolling. You feel disoriented and worried that you might lose your original view.

It’s also hard to know that a filter is even applied. With so little real estate on a given page, it’s hard to keep the entirety of the context in sight.

Sometimes, targets are hard to hit with sausage fingers. Of course, there are standards of usability, but clearly, not everyone read the book.

We also get varying experiences whether we’re in a browser or in a native app. In-browser interactions often feel jerky because the browser UI might pop in and out of view depending on the direction you’re scrolling in. Native apps have much more control over how it feels to navigate around, but launching a brand new app is a costly team decision.

## Layout & Positioning is key on mobile

When it comes to layout and positioning, the typical options are

![animated gif showing a mobile ui where filters are accessed through an icon on the top left of the screen](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/65ef0348abcd3b71cdff8ab9_Positioning-1-Top-drawer.gif)

**A top drawer that expands down**

Having filters live at the top of the page is pretty expected. The eye will inevitably scan over them. It’s also natural for them to even live inside the table header row.

**A bottom drawer that expands up**

With a bottom drawer you’d have to be sure it sticks on top of the content so it’s always visible. This is precisely what will make the filter button hard to miss; it’ll overlap on top of users’ precious data and it’s easier to reach with thumbs.

![ui example of a mobile device where filters open up as a bottom drawer](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/65ef03488bc88afb2173b456_Positioning-2-Bottom-drawer.gif)

![ui example of a mobile device where filters open up as a side drawer](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/65ef0348d7e75a035d9d4d81_Positioning-3-Sidebar.gif)

**A sidebar type of overlay**

Having filters move-in as a sidebar provides more room to keep relevant parts of the background visible. You get to keep the left-most content visible, which is typically the most recognizable part. This helps users maintain context and feel safe that their original page isn’t lost.

And with all of those you can go two different routes:

**Full-screen form type of flow**

Any of these positionings can lead to a full-page filtering experience. This way to do it gives a lot of room to open and close dropdowns, navigate around all the filters, before being satisfied and clicking ‘Apply’.

The full-screen way might be more useful for use cases where the user knows exactly what they’re looking for and tends to use multiple filters at one.

![screenshot of Salesmate mobile UI where filtering is a full-screen experience](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/65ef03488bc88afb2173b452_Salesmate.webp)

###### On mobile, Salesmate offers a full-screen filtering experience. A more immersive flow like this makes sense for advanced filters that allow for maximum precision.

**Keep original page in view but grayed-out**

No matter the positioning of the filters, you can also limit its size and style it in a way that it looks simply overlaid on top of the original content. Adding a subtle transparent overlay can help users recognize they’re in a temporary flow “on top” of the page.

This way can be beneficial for users who want to see the results refresh in real time so they get a sense of how the filters they choose are affecting the data.

Overall it’s important to help your users keep their bearings. Help them maintain context by still displaying a grayed-out portion of what’s underneath. Make sure to offer a quick opt-out by having the close button always visible, or by allowing them to tap the grayed-out area to click out.

## How & When to fetch

The same fetching methods from our [original piece](https://pencilandpaper.io/articles/ux-pattern-analysis-enterprise-filtering/) apply here. Let’s look at them through the considerations of mobile behaviour.

### Live-Filtering

🔴 Live-filtering means that the system pulls new results with every interaction done on the filters.

Selecting a single item from a checkbox list? Fetch. Moving a threshold slider by one pixel? Fetch. Changing your date range’s start date? Fetch.

We would typically not recommend this one because the whole screen gets refreshed at every click and you risk getting abruptly kicked out of the filter drawer.

Unless, that is, if you update in the background (keep the drawer open). This way you provide immediate feedback while preserving the user’s sense of place. But your data has to be clean so that fetching feels almost immediate.

![animated gif of Google Fonts on mobile where filters fetch live results as soon as they are selected](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/68e99d9c4cba5c7a442afb2d_Google-Fonts-Live-filtering-min%20comp50%20fuzz4.gif)

Google went with a live filtering fetching method. As shown, results refresh as soon as any filter selection is modified.

‍

### Per-filter

🟡 In a per-filter scenario, refreshing happens as the dropdown gets closed. This one could work well because it requires less taps, but your performance has to be A1.

For that you’ll need to account for extra room for an “Apply” button in each dropdown. Or you can also make it so that clicking the dropdown again closes it up and triggers the refresh.

Determine what the trigger is for a multi select vs single select. For example, if you know only one value is selectable from a dropdown list, you can have it so that a single click selects the item, closes the dropdown AND triggers the refresh. Bam.

### Batch filtering

🟢 Batch-filtering is when you fetch only once, at the very end of the user selection. This option makes the most sense for enterprise products on mobile.

This gives users dedicated time to think their selection through, scan all the options and hit the Apply hard with a super refined query.  Once users are done with their selection, they Apply to click out of the filter drawer and explicitly ask for results.

Again, this might not perfectly fit your users’ use cases. Batch-filtering makes it harder to be exploratory since you need to know what you’re looking for.

## UX Patterns you can use

Here are some pattern tips & tricks to enhance mobile filtering in your enterprise product.

### Progressive disclosure

For enterprise contexts, you’ll want to leverage expandable sections and dropdowns. If you just expose everything right from the start, your users will get scrolling vertigo and risk feeling overwhelmed.

![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/66d0ddaf11e0c2c7c707a57c_66d0dda981db2915718c8c62_filter-mobile-shmarket.gif)

###### On the Shelter Market website, all filters are collapsible and they display the selection in real time at the top of the sidebar. (P.S. Yes I know this is an e-commerce example, gotta do what ya gotta do)

There’s going to be a lot of clicking. Which is fine on mobile, because the targets are close to each other, only a few millimeters apart. And 21st century human fingers move fast on glass screens.

As much as we encourage nesting and hiding stuff behind taps, one exception has to be for the Apply button. Users shouldn’t have to scroll to get to it. It should remain sticky, at the top or bottom, always in view.

### Be selective

You don’t need to display everything. If the content itself, say a table, already has a reduced number of columns displayed on your mobile version, you don’t have to reflect all the filters as well.

There’s going to be a lot of clicking. Which is fine on mobile, because the targets are close to each other, only a few millimeters apart. And 21st century human fingers move fast on glass screens.

As much as we encourage nesting and hiding stuff behind taps, one exception has to be for the Apply button. Users shouldn’t have to scroll to get to it. It should remain sticky, at the top or bottom, always in view.

### Be selective

You don’t need to display everything. If the content itself, say a table, already has a reduced number of columns displayed on your mobile version, you don’t have to reflect all the filters as well.

### Offer “quick filters”

Limit the number of dropdowns. If a filter has 2 or 3 standardized options, check if you couldn’t instead display it as a switcher/picker.

Similarly, if a filter’s options offer numerical ranges, consider building a slider in.

![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/66d0eee4a67fec00a425330f_66d0ecf4d17efe7c5b4b6f14_mobile-filter-1.webp)

###### When the number of options is limited in a certain filter, it might be worth making it into a switcher, reducing the number of taps required to reach it. In this case, there are a limited region and they can fit in a horizontal element.

![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/66d0eee4a67fec00a4253312_66d0ecfe67ecc181f8f07402_mobile-filter-2.webp)

###### Consider utilizing sliders if it's suitable for the use case. If the range you're dealing with is high, the user may not be able to pinpoint the exact value they want with ease unless there are other interactive guardrails in place (like magnetizing to key values). In this example, the vertical space it saves is prioritized.

### Accelerate selections

Offer a “Select All” whenever you can. By offering more ways to do a selection (for example, tapping “Select All” and deselecting specific items), you increase the chances of a speedy input.

### Don’t be afraid of big target areas

Make your selectors easy to select for fingers

![example of the Peloton app on tablet where filters are displayed in a central modal with big visual buttons](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/65ef042c5e094f98ad18bac5_Peloton-Length-Picker.gif)

###### Peloton makes great use of real estate by using big button-like targets in two columns for their length options

### Allow users to save presets

Offer your users the ability to save their selection as a preset, so they can quickly switch in and out of their preferred views.

Especially for batch-filtering scenarios. Some power-users make filtering an art, they know exactly the way they want to see their data, the way it’s sorted and everything. Your filtering feature should honour that. Hey if it helps them in their workflow, it should make your team happy too!

### Embrace the OS

Make sure the native components are used as much as possible. Not everyone knows this (shhh…) but OSes come with dropdown lists. USE THEM! Don’t try to reinvent the wheel here. Just like you wouldn’t code a whole mobile keyboard to ensure your users can input stuff. It’s wasted front-end effort and besides, it’ll likely up your performance if you don’t have to render custom dropdown overlays that respond weirdly to other stuff happening on the page.

I mean… Even Google can’t do it.

The thing about these native components is that they’re simply the best version out there. They were made by the very people who built the OS, these components are optimized to the brim. Plus, as users, they’re the ones we’ve used most often. We know how they work, they’re optimized for hand positioning and gestures. You just can’t go wrong with native.

![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/66d0ddaf11e0c2c7c707a586_66d0dd48ab30595cab75b2a4_mobile-filter-google.gif)

###### On the Google Fonts website, when those custom dropdowns are scrollable or the inputs are draggable, it quickly interferes with the browser’s scroll triggers, making for suboptimal interactions.

## Wrapping up

First off, congrats on taking on the challenge of offering your users a way to access deeper functionality on your enterprise system while on-the-go. If this made it to your roadmap, surely lots of folks will be happy.

As you design and build, make sure you find all the little places where you can provide additional help. Adapting your inputs for touch targets, revisiting the way you fetch, taking advantage of native elements in your chosen mobile environment.

As always, the better you know your users and their usecases, the more intuitive the experience will feel for them.

We hope this will help you on your journey, and we’d love to see how your mobile enterprise filters are being used in the wild!

## Data-rich design, but easier

## Our secret methodology for features that hinge on data.

Our **Data Mapping Workshop** sets you up to design any dashboard, filter, data table or search experience like a total pro, creating better initial designs off the bat and iterating higher quality end results. Stop struggling to understand the material you're working with, take control and make better design!

## Data Mapping Workshop

$499 USD

[Learn More](https://www.pencilandpaper.io/product/enterprise-data-mapping-workshop)

## Continue Reading...

[![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/67472041233438303869f0bb_hero-article-filters.webp)\\
\\
**Filter UX Design Patterns** \\
\\
Is it just us, or do all resources about filtering UX revolve around e-commerce? It might be “easier” to document the ins and outs of an interaction where you have control over the...](https://www.pencilandpaper.io/articles/ux-pattern-analysis-enterprise-filtering)

[![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/670ef61f2c459ae89f008605_articles-breadcrumb-pattern.webp)\\
\\
**Breadcrumbs UX Navigation – The Ultimate Design Guide** \\
\\
Breadcrumbs in the UI sense are fascinating. On first inspection, breadcrumbs seem easy peasy, but...](https://www.pencilandpaper.io/articles/breadcrumbs-ux)

[![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/670ef8738c7ccd32c8a04230_articles-data-table-pattern%20(1).webp)\\
\\
**Data Table Design UX Patterns** \\
\\
Enterprise software companies regularly serve up large quantities of data to their users, making well designed table experiences are a priority. Before embarking on...](https://www.pencilandpaper.io/articles/ux-pattern-analysis-enterprise-data-tables)

[![](https://cdn.prod.website-files.com/65d605a3b4417479c154329f/6709871a6a9a2ab789399e19_ux-training-benefits-article-hero.webp)\\
\\
**UX Training Benefits for Your Product Team** \\
\\
To achieve truly great UX and see the ROI, you need to get many people on board with the UX mindset. This includes those closest to the product like developers...](https://www.pencilandpaper.io/articles/ux-training-benefits-for-your-product-team)

## Download our Table UX Audit Checklist

Do a mini UX audit on your table views & find your trouble spots with this free guide.

Available in a printable version (pdf).

_Please fill in the form below and it will be in your inbox shortly after._

Whats your name?

Whats your email?\*

Can we email you?

Yes, I'd like to receive marketing emails from Pencil & Paper

This form collects your name and email so we can add you to our email list and send you our newsletter full of helpful insights and updates. Please read our [privacy policy](https://www.pencilandpaper.io/privacy-policy) to understand how we protect and manage your data.

Thank you! Your submission has been received!

Oops! Something went wrong while submitting the form.

![letters](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65eede2a0f31509011751e08_letters.png)

## Want to dig deeper on flow diagrams?

Be the first to know about our upcoming release!

_If you found this intro content useful and find yourself needing to express yourself more efficiently on your software team, this training is for you. Our new flowchart training includes real-life enterprise stories and examples for using flowcharts for UX. You’ll get tips on how to make your diagramming efforts successful, how to derive info for the flow charts, and how to get others to use and participate in the diagramming process._

Whats your name?\*

Whats your role?\*

RoleDeveloperDesignerProductDev Team LeadQASalesMarketingCustomer SupportOther

Whats your email?\*

Would you like to join our newsletter?

Yes, sign me up!

This form collects your name and email so we can add you to our email list and send you our newsletter full of helpful insights and updates. Please read our [privacy policy](https://www.pencilandpaper.io/privacy-policy) to understand how we protect and manage your data.

Thank you! Your submission has been received!

Oops! Something went wrong while submitting the form.

 [Contact Us](https://www.pencilandpaper.io/contact-us)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66621b3c8194cdd9acfeed5c_card-intro-ux.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Intro to UX for Teams**  **A fun, high-impact injection that levels up your entire team and gets UX alignment without all the fluff. We cover everything from the basics of UX to real-life, enterprise examples that you might just sound a little familiar.** \\
\\
For up to 20 team members\\
\\
7 Videos\\
\\
55 min\\
\\
**$1000 USD**](https://www.pencilandpaper.io/product/intro-to-ux-for-teams-masterclass)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb9d4f373b6ead411f7ce_blue-icon-team.webp)

### Explore our UX/UI Services

### Curious about the possibility of working with the P&P crew on your enterprise software project? Check out our services.

[Our services](https://www.pencilandpaper.io/services-2024)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb4a737fa4432a754c7e6_blue-icon-mail.svg)

### Join our newsletter

### Bringing enterprise-grade UX resources into the world to help you think better and have more interesting conversations with your crew!

[Newsletter sign up](https://www.pencilandpaper.io/newsletter)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666730a100e30c29cd88be49_card-tables-checklist.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Data Tables Checklist**  **This free checklist lets you double check your data tables for their UX quality and assess various aspects which make or break the data table experience for your users.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/data-tables-ux-checklist-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666748efbf81ce11ac40b99b_card-datatables.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Data Tables Masterclass**  **We’ve crafted the masterclass to enrich and expand upon your experience reading our article. Peppering in design principles, more examples and workflow nuances that’ll help you deliver high quality UX.** \\
\\
90 MIN\\
\\
**$149**  **$99 USD**](https://www.pencilandpaper.io/product/data-tables-masterclass)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666730a100e30c29cd88be49_card-tables-checklist.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Data Tables Checklist**  **This free checklist lets you double check your data tables for their UX quality and assess various aspects which make or break the data table experience for your users.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/data-tables-ux-checklist-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/665fa8becc9e4a74f1a60b04_card-handbook-outline.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Design Handbook Outline**  **This outline gives you a framework for how to build your own design handbook. It’s the stuff you want to include in your handbook, or at least consider in the process. Take this as a starting point, and adjust it to fit your team’s size, culture, and design maturity.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/design-handbook-outline-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66688ce59bc6c97647cda233_card-interaction-design-masterclass.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Enterprise Interaction Design Masterclass**  **Learn the foundation that P&P uses to think through interaction patterns, reframe what UX quality to aim for and discover states beyond the basics like hover and disabled...** \\
\\
55 min\\
\\
**$150 USD**](https://www.pencilandpaper.io/product/interaction-design-masterclass)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666730a100e30c29cd88be49_card-tables-checklist.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Data Tables Checklist**  **This free checklist lets you double check your data tables for their UX quality and assess various aspects which make or break the data table experience for your users.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/data-tables-ux-checklist-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/665fa8becc9e4a74f1a60b04_card-handbook-outline.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Design Handbook Outline**  **This outline gives you a framework for how to build your own design handbook. It’s the stuff you want to include in your handbook, or at least consider in the process. Take this as a starting point, and adjust it to fit your team’s size, culture, and design maturity.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/design-handbook-outline-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66688ce59bc6c97647cda233_card-interaction-design-masterclass.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Enterprise Interaction Design Masterclass**  **Learn the foundation that P&P uses to think through interaction patterns, reframe what UX quality to aim for and discover states beyond the basics like hover and disabled...** \\
\\
55 min\\
\\
**$150 USD**](https://www.pencilandpaper.io/product/interaction-design-masterclass)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb4a7ff7a65fee96857f7_blue-icon-book.svg)

### Curious about our Products for Enterprise software?

### Check out what other goodies we have for you and your team

[Explore products](https://www.pencilandpaper.io/products)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666730a100e30c29cd88be49_card-tables-checklist.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Data Tables Checklist**  **This free checklist lets you double check your data tables for their UX quality and assess various aspects which make or break the data table experience for your users.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/data-tables-ux-checklist-download)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb9d4f373b6ead411f7ce_blue-icon-team.webp)

### Explore our UX/UI Services

### Curious about the possibility of working with the P&P crew on your enterprise software project? Check out our services.

[Our services](https://www.pencilandpaper.io/services-2024)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb4a737fa4432a754c7e6_blue-icon-mail.svg)

### Join our newsletter

### Bringing enterprise-grade UX resources into the world to help you think better and have more interesting conversations with your crew!

[Newsletter sign up](https://www.pencilandpaper.io/newsletter)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66d8e7475098f9b50752b640_icon-pink-video.svg)

## Interaction Design Masterclass

Ready to level up with a 1 hour masterclass full of real, enterprise-grade examples?

[Check out the Masterclass](https://www.pencilandpaper.io/product/interaction-design-masterclass)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/672146d306b1b6631d3e9877_icon-pink-person-chat.svg)

## Need expert ux help?

Explore your needs and possible solutions in a free, 30 minute session with us.

[Book Free Session](https://pencilpaper.pipedrive.com/scheduler/PPdJwPHB/30-minute-ux-session)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66d8e74dd8f00a4a0be05db6_icon-pink-list-pencil.svg)

## Get your free Redesign Assessment Checklist!

We've put together a 14 page PDF with situational questions in a variety of focus areas to help you figure out what kind of needs and solutions you can explore for your software.

[Get the Redesign Assement Checklist](https://www.pencilandpaper.io/software-redesign-assessment-checklist)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6671efc51ff997aee954764a_icon-pink-vector-ruler-pencil.svg)

## Get your Heuristic Report Template Kit

Spend your time and life force actually doing your heuristic evaluation, rather than endless visual fiddling. Complete with a easy to customize Figma file and comprehensive how to videos!

[Check out the Heuristic Report Template Kit](https://www.pencilandpaper.io/product/ux-heuristic-report-template-kit-download)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666730a100e30c29cd88be49_card-tables-checklist.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Data Tables Checklist**  **This free checklist lets you double check your data tables for their UX quality and assess various aspects which make or break the data table experience for your users.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/data-tables-ux-checklist-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/665fa8becc9e4a74f1a60b04_card-handbook-outline.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bab02242b05d5f531_prod-type-download.svg)\\
\\
**Design Handbook Outline**  **This outline gives you a framework for how to build your own design handbook. It’s the stuff you want to include in your handbook, or at least consider in the process. Take this as a starting point, and adjust it to fit your team’s size, culture, and design maturity.** \\
\\
PDF\\
\\
**Free**](https://www.pencilandpaper.io/product/design-handbook-outline-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66688ce59bc6c97647cda233_card-interaction-design-masterclass.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Enterprise Interaction Design Masterclass**  **Learn the foundation that P&P uses to think through interaction patterns, reframe what UX quality to aim for and discover states beyond the basics like hover and disabled...** \\
\\
55 min\\
\\
**$150 USD**](https://www.pencilandpaper.io/product/interaction-design-masterclass)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667397619c43e6fc4da13d5_card-loading.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Loading Masterclass**  **Dive into the nuances around representing loading in enterprise software. We explore how to adapt to technical constraints and deliver a great experience regardless of how long it takes to load.** \\
\\
50 Min\\
\\
**Free**](https://www.pencilandpaper.io/product/loading-masterclass) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66688ce59bc6c97647cda233_card-interaction-design-masterclass.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Enterprise Interaction Design Masterclass**  **Learn the foundation that P&P uses to think through interaction patterns, reframe what UX quality to aim for and discover states beyond the basics like hover and disabled...** \\
\\
55 min\\
\\
**$150 USD**](https://www.pencilandpaper.io/product/interaction-design-masterclass)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb4a7ff7a65fee96857f7_blue-icon-book.svg)

### Curious about our Products for Enterprise software?

### Check out what other goodies we have for you and your team

[Explore products](https://www.pencilandpaper.io/archive/products-old)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66621b3c8194cdd9acfeed5c_card-intro-ux.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6667999bbad0589ef07d8bab_prod-type-tv.svg)\\
\\
**Intro to UX for Teams**  **Learn the foundation that P&P uses to think through all interaction patterns, including errors, success and warnings** \\
\\
55 min\\
\\
**$90 USD**](https://www.pencilandpaper.io/product/intro-to-ux-for-teams-masterclass) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66621b3c37ae9322cd10c619_card-heuristic-kit.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6668977bfeb7b2638d5e868f_prod-type-figma.svg)\\
\\
**Heuristic Report Template Kit**  **Spend your time and life force actually doing your heuristic evaluation, rather than endless visual fiddling. Complete with a easy to customize Figma file and comprehensive how to videos to guide you the whole way.** \\
\\
Figma\\
\\
**$79**  **$59 USD**](https://www.pencilandpaper.io/product/ux-heuristic-report-template-kit-download)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb4a7ff7a65fee96857f7_blue-icon-book.svg)

### Curious about our Products for Enterprise software?

### Check out what other goodies we have for you and your team

[Explore products](https://www.pencilandpaper.io/products)

[![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66621b3c37ae9322cd10c619_card-heuristic-kit.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/6668977bfeb7b2638d5e868f_prod-type-figma.svg)\\
\\
**Heuristic Report Template Kit**  **Complete with a easy to customize Figma file and comprehensive how to videos to guide you the whole way.** \\
\\
Figma\\
\\
**$79**  **$59 USD**](https://www.pencilandpaper.io/product/ux-heuristic-report-template-kit-download) [![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/667da6088a6cf46913671672_service-ux-audit-card.webp)\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/66393cde85ac29c0a83583bf_white-swave.svg)\\
\\
![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/667da7a95afc3e929f4c98fc_icon-type-sparkle-service.svg)\\
\\
**UX Audit Service**  **Not sure where to start tackling your UX debt and need a path forward? The P&P crew has all the know how on where to get started.** \\
\\
Custom UX Audit\\
\\
**Get in touch**](https://www.pencilandpaper.io/services/ux-audit)

![](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/666cb4a7ff7a65fee96857f7_blue-icon-book.svg)

### Curious about our Products for Enterprise software?

### Check out what other goodies we have for you and your team

[Explore products](https://www.pencilandpaper.io/archive/products-old)

[![pencil & paper Logo](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65d33e9e42ee14a5d6108b79_logowhite.svg)](https://www.pencilandpaper.io/)

We strive to make people’s lives easier by designing satisfying interactions that help bridge the human/computer divide.

[Learn more about us.](https://www.pencilandpaper.io/about)

![love canada logo](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65d33fbf017d17ecbcf89998_lovecanada.svg)

A proudly Canadian Design Company

3 Fan Tan Alley Suite 400, Victoria, BC, V8W 3G9

[Write us](https://www.pencilandpaper.io/contact-us)

Shortcuts

[About](https://www.pencilandpaper.io/about) [Services](https://www.pencilandpaper.io/services-2024) [Products](https://www.pencilandpaper.io/products) [Articles](https://www.pencilandpaper.io/articles) [Login](https://labs.pencilandpaper.io/login/)

Connect

[Youtube](https://www.youtube.com/@pencilpaperlabs) [LinkedIn](https://www.linkedin.com/company/pencil-and-paper) [Twitter](https://link.pencilandpaper.io/twitter) [Instagram](https://www.instagram.com/pencilpaperlabs/)

[Join Our Newsletter](https://www.pencilandpaper.io/newsletter)

© 2024 Pencil & Paper Design Company.

[Terms & Conditions](https://www.pencilandpaper.io/terms-conditions) [Privacy Policy](https://www.pencilandpaper.io/privacy-policy) [Cookie Policy](https://www.pencilandpaper.io/cookie-policy)

[![linkedin](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65e5d3b2c04ed8dbfea5eb9c_linkedin%20(1).webp)](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#)[![twitter](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65e5d3b2ec23f1f40ff2d59e_twitter.webp)](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#)[![facebook](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65e5d3b2600cf437a7ab4b1c_facebook-app-symbol.webp)](https://www.pencilandpaper.io/articles/ux-pattern-analysis-mobile-filters#)

![share icon](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65e5d30a85966f69c54075aa_share.webp)

## Be the first to know

Join our newsletter

Thank you! Your submission has been received!

Oops! Something went wrong while submitting the form.

This form collects your name and email so we can add you to our email list and send you our newsletter full of helpful insights and updates.  Please read our [Privacy Policy](https://www.pencilandpaper.io/privacy-policy) to understand how we protect and manage your data.

![close](https://cdn.prod.website-files.com/65d32a145451f865e1ca2bbe/65e6e8739a35afe6e1583c3a_close%20(1).webp)