{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "sandbox"
, dependencies =
  [ "affjax"
  , "argonaut-codecs"
  , "console"
  , "effect"
  , "exceptions"
  , "js-timers"
  , "profunctor-lenses"
  , "psci-support"
  , "react-basic-dom"
  , "react-basic-hooks"
  , "semirings"
  , "simple-json"
  , "strings"
  , "validation"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
