module App where

import Prelude
import Affjax as Affjax
import Affjax.ResponseFormat as ResponseFormat
import Control.Monad.Except (ExceptT(..), except, runExceptT)
import Data.Argonaut.Decode as Argonaut
import Data.Array ((:))
import Data.Array as Array
import Data.Bifunctor (lmap)
import Data.Either (either)
import Data.Foldable (for_)
import Data.FoldableWithIndex (foldMapWithIndex)
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Foreign.Object (Object)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic.DOM as R
import React.Basic.DOM.Events (targetValue)
import React.Basic.Events (handler, handler_)
import React.Basic.Hooks (Component, JSX, component, fragment, useState, useState', (/\))
import React.Basic.Hooks as React
import React.Basic.Hooks.Aff (useAff)

mkApp :: Component Unit
mkApp = do
  breedsComponent <- mkBreeds
  component "App" \_ -> React.do
    breeds /\ setBreeds <- useState' Pending
    enableSubBreeds /\ setEnableSubBreeds <- useState false
    search /\ setSearch <- useState' (Pattern "")
    useAff unit do
      dogs <- runExceptT fetchBreeds
      liftEffect (setBreeds (either Failure Success dogs))
    pure do
      fragment
        [ R.header_
            [ R.h1_ [ R.text "Dogs!" ]
            , R.input
                { onChange: handler targetValue \value -> setSearch (Pattern (fromMaybe "" value))
                }
            , R.label_
                [ R.input
                    { onChange: handler_ (setEnableSubBreeds not)
                    , checked: enableSubBreeds
                    , type: "checkbox"
                    }
                , R.text "Enable sub-breeds"
                ]
            ]
        , R.section_
            [ case breeds of
                Pending -> R.text "Loading..."
                Failure err -> displayAppError err
                Success breeds' ->
                  breedsComponent do
                    breeds'
                      # Array.filter (\{ subBreed } -> enableSubBreeds || subBreed == Nothing)
                      # Array.filter
                          ( \{ breed, subBreed } ->
                              containsCaseInsensitive search breed
                                || maybe false (containsCaseInsensitive search) subBreed
                          )
                      # Array.sortWith displayBreed
                      # Array.take 12
            ]
        ]

data FetchingData e a
  = Pending
  | Failure e
  | Success a

type Breed
  = { breed :: String
    , subBreed :: Maybe String
    }

data AppError
  = FetchError Affjax.Error
  | DecodeError Argonaut.JsonDecodeError

containsCaseInsensitive :: Pattern -> String -> Boolean
containsCaseInsensitive (Pattern pat) str = String.contains (Pattern (String.toLower pat)) (String.toLower str)

displayAppError :: AppError -> JSX
displayAppError = case _ of
  FetchError err -> displayError (Affjax.printError err)
  DecodeError err -> displayError (Argonaut.printJsonDecodeError err)
  where
  displayError msg =
    R.div
      { className: "error"
      , children:
          [ R.h2_ [ R.text "Error fetching from API" ]
          , R.pre_ [ R.text msg ]
          ]
      }

mkBreeds :: Component (Array Breed)
mkBreeds = do
  breedButton <- mkBreedButton
  component "Breeds" \breeds -> React.do
    selectedBreed /\ setSelectedBreed <- useState' Nothing
    breedImages /\ setBreedImages <- useState' Pending
    useAff selectedBreed do
      dogs <- runExceptT (for_ selectedBreed fetchBreedImages)
      liftEffect (setBreedImages (either Failure Success dogs))
    let
      breedButtons =
        R.ul_
          <<< map \breed -> R.li_ [ breedButton { breed, onClick: setSelectedBreed (Just breed) } ]
    pure
      if Array.null breeds then
        R.h2_ [ R.text "No matches" ]
      else
        breedButtons breeds

mkBreedButton :: Component { breed :: Breed, onClick :: Effect Unit }
mkBreedButton = do
  component "BreedButton" \props ->
    pure do
      R.button
        { onClick: handler_ props.onClick
        , children: [ R.text (displayBreed props.breed) ]
        }

displayBreed :: Breed -> String
displayBreed = case _ of
  { breed: "australian", subBreed: Just "shepherd" } -> "australian shepherd" -- Bad data
  { breed, subBreed: Just sb } -> sb <> " " <> breed
  { breed, subBreed: Nothing } -> breed

-- | 
fetchBreeds :: ExceptT AppError Aff (Array Breed)
fetchBreeds = do
  { body } <-
    ExceptT do
      Affjax.get ResponseFormat.json "https://dog.ceo/api/breeds/list/all" <#> lmap FetchError
  { message } :: { message :: Object (Array String) } <-
    except do
      Argonaut.decodeJson body # lmap DecodeError
  pure do
    message
      # foldMapWithIndex \breed subBreeds ->
          { breed, subBreed: Nothing }
            : (subBreeds <#> \subBreed -> { breed, subBreed: Just subBreed })

fetchBreedImages :: Breed -> ExceptT AppError Aff (Array String)
fetchBreedImages = do
  unsafeCrashWith "Not implemented"
