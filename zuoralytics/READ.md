#Overview
These models are an example of how to work up a model for doing susbcription based reporting on Zuora data.  For a tool built for the "subscription economy" Zuora sure doesn't make it easy to build subscription reporting, but in 3 steps you can build a 'subscription versions' table that will allow you to do analysis on changes to your subscription base over time.  This model assumes that you are using Zuora discounts.  If you aren't, your life is much easier and you can ignore the plan_discounts portion of this model.

#Zuora Object Model
Zuora's object model is vast and deep, like the ocean.  It can handle almost any subscription use case at the price of being somewhat complicated for your average SaaS business.  A simplified description of the relevant objects is below:

##Key Objects
Accounts --> Entities that pay you money

Subscriptions --> An agreement between your business and an account that the account has a subscription for X amount of time with you.  Think of a subscription as a basket you can place multiple products into, not a representation of the products in that basket.

Amendments --> Amendments represent changes to subscriptions.  When you "amend" a subscription you create a new subscription object (new 'version' of the subscription) and an amendment object.

Rate Plans --> Bundles of products.  Rate plans are added to subscriptions, beyond that they are pretty useless for reporting and we will skip them in the our model by joining rate_plan_charges directly onto subscriptions.

Rate Plan Charges --> The actual subscription products and discounts.  A rate plan charge either represents a charge to a subscription or a discount that will impact other rate_plan_charges (Why? Ask Zuora. I have no idea.)  They contain information about the quantity of a product and the billing schedule.

Rate Plan Charge Tiers --> For tiered/volume pricing, the different tier-quantity prices available.  The price, discount amount, and discount percentage fields live here.

##Important Relationships
Accounts have many subscriptions
Subscriptions have one amendment (the amendment that created the subscription)
Subscriptions have many rate_plans
Rate_plans have many rate_plan_charges
Rate_plan_charges have many rate_plan_charge_tiers

#Model Explanation
This model aims to start at the bottom of the object model (rate_plan_charges/tiers) and work up to a table of the different 'versions' for a subscription

##Plan_discounts (this is the tricky one)
Plan_discounts does three things
1. Joins the correct price tier onto each rate_plan to get key fields like price, discount percentage and discount amount   
2. Joins rate_plan_charges that represent discounts onto the rate_plan_charges that represent plans impacted by those discounts.  Since this is a many to many relationship (discounts can impact multiple rate_plans and rate_plans can be impacted by several discounts) you will typically get several of these plan_discount combinations.  We decide if a discount impacts a rate_plan based on if they are 'active' within the same subscription version.  (This is imperfect, but works in 95% of cases)
3. Aggregates the plan_discounts using group by / agg functions to obtain a single row for each "product" a customer has on their subscriptions

##Subscription Versions
Now that we have a row for each product on a subscription we need to roll this up into a single subscription.  Subscription versions takes our plan_discounts table and rolls them up into a single 'version' of a subscription including the start / end amendments

##Subscription Version Changes
Now that we have clean 'versions' of each subscription the final step is to understand the changes!  We self-join subscription versions to obtain a row of |Subscription Version Fields|Previous Subscription Version Fields|Changes (Calculated)|.  An example of calculated 'change' fields would be 'MRR Delta' --> Version2 MRR - Version1 MRR

#Disclaimer
This model is still rough.  It works for the implementations of Zuora I am working on but makes several assumptions specific to our instance (which will be documented soon!).  I am pushing it out to the community to get feedback and to hopefully make life easier for the next person who has to do analytics on Zuora data.
