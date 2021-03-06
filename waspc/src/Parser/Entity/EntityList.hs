module Parser.Entity.EntityList
    ( entityList
    ) where

import Text.Parsec (choice)
import Text.Parsec.String (Parser)

import qualified Wasp.EntityList as WEL
import Wasp.EntityList (EntityList)

import qualified Wasp.JsCode as WJS

import qualified Parser.JsCode
import qualified Parser.Common as P
import qualified Parser.Entity.Common as PE
import qualified Util as U
import qualified Lexer as L

-- * EntityList

-- | Parses entity list, e.g. "entity-list<Task> TaskList {...}"
entityList :: Parser EntityList
entityList = do
    (entityName, listName, options) <-
        P.waspElementLinkedToEntity L.reservedNameEntityList (P.waspClosure entityListOptions)

    return WEL.EntityList
        { WEL._name = listName
        , WEL._entityName = entityName
        , WEL._showHeader = maybeGetListOptionShowHeader options
        , WEL._fields = getFieldsConfig options
        , WEL._mutexFilters = getMutexFilters options
        }

data EntityListOption
    = EloShowHeader Bool
    | EloFields [WEL.Field]
    | EloMutexFilters [WEL.Filter]
    deriving (Show, Eq)

entityListOptions :: Parser [EntityListOption]
-- TODO(matija): this could be further abstracted as waspClosureOptions option ->
-- that way we abstract L.commaSep
entityListOptions = L.commaSep entityListOption

entityListOption :: Parser EntityListOption
entityListOption = choice
    [ EloShowHeader <$> P.waspPropertyBool "showHeader"
    , entityListOptionFields
    , entityListOptionMutexFilters
    ]

-- * Show header

maybeGetListOptionShowHeader :: [EntityListOption] -> Maybe Bool
maybeGetListOptionShowHeader options = U.headSafe [b | EloShowHeader b <- options]

-- * Filters

getMutexFilters :: [EntityListOption] -> [WEL.Filter]
getMutexFilters options = case [fs | EloMutexFilters fs <- options] of
    [] -> []
    ls -> head ls

entityListOptionMutexFilters :: Parser EntityListOption
entityListOptionMutexFilters = EloMutexFilters <$> mutexFiltersP
    where
        mutexFiltersP :: Parser [WEL.Filter]
        mutexFiltersP = P.waspPropertyClosure "mutuallyExclusiveFilters" $
                        L.commaSep1 listPropertyFilter

listPropertyFilter :: Parser WEL.Filter
listPropertyFilter = do
    (filterName, predicate) <- P.waspPropertyWithIdentifierAsKey Parser.JsCode.jsCode

    return WEL.Filter
        { WEL._filterName = filterName
        , WEL._filterPredicate = predicate
        }

-- * Fields

getFieldsConfig :: [EntityListOption] -> [WEL.Field]
getFieldsConfig options = case [fs | EloFields fs <- options] of
    [] -> []
    ls -> head ls

entityListOptionFields :: Parser EntityListOption
entityListOptionFields = EloFields <$> PE.waspPropertyEntityFields fieldOption createFieldConfig

createFieldConfig :: (String, [FieldOption]) -> WEL.Field
createFieldConfig (fieldName, options) = WEL.Field
    { WEL._fieldName = fieldName
    , WEL._fieldRender = maybeGetFieldOptionRender options
    }

data FieldOption
    = FieldOptionRender WJS.JsCode

fieldOption :: Parser FieldOption
fieldOption = choice
    [ fieldOptionRender
    ]

fieldOptionRender :: Parser FieldOption
fieldOptionRender = FieldOptionRender <$> P.waspProperty "render" Parser.JsCode.jsCode

maybeGetFieldOptionRender :: [FieldOption] -> Maybe WJS.JsCode
maybeGetFieldOptionRender options = U.headSafe [js | FieldOptionRender js <- options]
