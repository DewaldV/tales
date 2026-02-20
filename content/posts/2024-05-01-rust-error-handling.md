+++
title = 'Learning Rust: Error handling with Result and Option'
date = 2024-05-01T08:54:00Z
draft = false
tags = ['rust', 'error-handling']
+++

## Learning Rust

Change below reflect growing understanding of handling errors cleanly in Rust.

From "Check result and expect" to "This is actually an error, let's map that to our Enum"

Some fun with learning more about error handling in Rust. The code here is interesting as someone moving from Go's model of errors of values to Rust's more Enum-driven world:

I have a function that finds a Pot in Monzo when given an auth token and name.

Since this can fail as it uses the network and Monzo API it returns `Result<Option<Pot>>`. `Result` for possible network and API errors and `Option` as we could not find a Pot.

The `?` at the end of `let found_pod` will return an error if one happened when finding the pot so the rest of the code deals with the `Option` side of things. I originally checked the Option to see if it is `None`, printed a messaged and returned. I then needed to extract the actual value with a `.expect` assertion since I know it's safe.

This was fine but I always felt it was a bit manual so in rethinking this I realised the obvious: A missing pot is an error for this function and I should just return an appropriately typed error to the caller which has the message to return to the client embedded.

So we instead convert the `Option` to a `Result` with `.ok_or` passing the error which maps to a missing Pot. Now we can read the pot out or return the new error with our usual `?` for error propogation.

```rust
pub enum Error {
+     #[error("no pot found with name={pot_name}")]
+    PotNotFound { pot_name: String },
...
```

```rust
     let found_pot = find_pot(token, pot_name).await?;
     
-    if found_pot.is_none() {
-        println!("No pot found with name: {}", pot_name);
-        return Ok(());
-    }
-
-    let pot = found_pot.expect("none checked above so this is safe");
     
+    let pot = found_pot.ok_or(Error::PotNotFound {
+        pot_name: String::from(pot_name),
+    })?;
```
