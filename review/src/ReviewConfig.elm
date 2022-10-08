module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Review.Rule exposing (Rule)
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDuplicatePorts
import NoEmptyText
import NoUnsafePorts
import NoUnusedPorts
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoFloatIds
import NoMissingDocumentation
import NoMissingSubscriptionsCall
import NoRecursiveUpdate
import NoUselessSubscriptions
import NoMissingTypeConstructor
import NoInconsistentAliases
import NoModuleOnExposedNames
import NoRedundantConcat
import NoRegex
import NoSinglePatternCase
import NoTypeAliasConstructorCall
import NoUnmatchedUnit
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoAlways
import Documentation.ReadmeLinksPointToCurrentVersion
import Docs.NoMissing exposing (exposedModules, onlyExposed)
import NoPrimitiveTypeAlias

config : List Rule
config =
    [ 
        -- NoDebug.Log.rule
    -- , NoDebug.TodoOrToString.rule
    NoDuplicatePorts.rule
    , NoUnsafePorts.rule NoUnsafePorts.any
    -- , NoUnusedPorts.rule -- don't think un-used port should fail build
    -- , NoEmptyText.rule
    , NoExposingEverything.rule
    , NoImportingEverything.rule ["Html"]
    , NoMissingTypeAnnotation.rule 
    -- , NoMissingTypeAnnotationInLetIn.rule -- this is insane
    -- , NoMissingTypeExpose.rule -- unsure how this works with Phantom types
    , NoFloatIds.rule
    -- , NoMissingDocumentation.rule -- this is a big one, need to come back to it
    -- , Docs.NoMissing.rule
    --     { document = onlyExposed
    --     , from = exposedModules
    --     }
    -- , NoMissingSubscriptionsCall.rule -- disagree with this one
    , NoRecursiveUpdate.rule 
    -- , NoUselessSubscriptions.rule
    , NoInconsistentAliases.config
    []
    |> NoInconsistentAliases.noMissingAliases
    |> NoInconsistentAliases.rule -- TODO: figure out what aliases we're trying sync here
    , NoModuleOnExposedNames.rule 
    , NoRedundantConcat.rule
    , NoRegex.rule
    , NoSinglePatternCase.rule NoSinglePatternCase.fixInArgument -- TODO: figure how much work this is given our phantom types
    , NoTypeAliasConstructorCall.rule -- If this becaomes painful, disable, but helps with primitive obession
    -- , NoUnmatchedUnit.rule -- this one is dumb
    -- , NoUnused.CustomTypeConstructorArgs.rule -- TODO: enable, but refactor Merchant parsing first because of _ _ _ _ _ _ _ 
    -- , NoUnused.CustomTypeConstructors.rule [] -- TODO: enable, just ensure configured for our phantom types
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule -- TODO: review if you start making pages/larger size app
    , NoUnused.Modules.rule -- TODO: same as bove
    , NoUnused.Parameters.rule -- TODO: verify if holes negate this rule
    , NoUnused.Patterns.rule
    -- , NoUnused.Variables.rule
    -- , NoAlways.rule
    -- , Documentation.ReadmeLinksPointToCurrentVersion.rule -- TODO: figure out if we can use with Docs.NoMissing
    , NoPrimitiveTypeAlias.rule
    ]
    |> List.map (Review.Rule.ignoreErrorsForDirectories [ "src/Api/", "tests/" ])