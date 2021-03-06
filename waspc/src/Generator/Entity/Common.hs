module Generator.Entity.Common
    ( entityTemplatesDirPath
    , entityDirPathInSrc
    , entityTemplateData
    , entityComponentsDirPathInSrc
    , entityFieldToJsonWithTypeAsKey
    , addEntityFieldTypeToJsonAsKeyWithValueTrue
    , getEntityLowerName
    , getEntityClassName
    ) where

import Data.Maybe (fromJust)
import Data.Aeson ((.=), object)
import qualified Data.Aeson as Aeson
import qualified Data.Text as Text
import Path ((</>), reldir)
import qualified Path
import qualified Path.Aliases as Path

import qualified Util
import Wasp

-- | Path of the entity-related generated code, relative to src/ directory.
entityDirPathInSrc :: Entity -> Path.RelDir
entityDirPathInSrc entity = [reldir|entities|] </>
                            (fromJust $ Path.parseRelDir $ Util.camelToKebabCase (entityName entity))

-- | Path of the code generated for entity components, relative to src/ directory.
entityComponentsDirPathInSrc :: Entity -> Path.RelDir
entityComponentsDirPathInSrc entity = (entityDirPathInSrc entity) </> [reldir|components|]

-- | Location in templates where entity related templates reside.
entityTemplatesDirPath :: Path.RelDir
entityTemplatesDirPath = [reldir|src|] </> [reldir|entities|] </> [reldir|_entity|]

-- | Default generic data for entity templates.
entityTemplateData :: Wasp -> Entity -> Aeson.Value
entityTemplateData wasp entity = object
    [ "wasp" .= wasp
    , "entity" .= entity
    , "entityLowerName" .= getEntityLowerName entity
    , "entityUpperName" .= getEntityUpperName entity
    -- TODO: use it also when creating Class file itself and in other files.
    , "entityClassName" .= getEntityClassName entity
    , "entityTypedFields" .= map entityFieldToJsonWithTypeAsKey (entityFields entity)
    -- Below are shorthands, so that templates are more readable.
    -- Each one has comment example for Task entity.
    , "_entity" .= getEntityLowerName entity  -- task
    , "_entities" .= ((getEntityLowerName entity) ++ "s")  -- tasks
    , "_Entity" .= getEntityUpperName entity  -- Task
    , "_Entities" .= ((getEntityUpperName entity) ++ "s")  -- Tasks
    , "_e" .= [head $ getEntityLowerName entity]  -- t
    , "_es" .= ((head $ getEntityLowerName entity) : "s")  -- ts
    ]

getEntityLowerName :: Entity -> String
getEntityLowerName = Util.toLowerFirst . entityName

getEntityUpperName :: Entity -> String
getEntityUpperName = Util.toUpperFirst . entityName

getEntityClassName :: Entity -> String
getEntityClassName = getEntityUpperName

{- | Converts entity field to a JSON where field type is a key set to true, along with
all other field properties.

E.g.:
boolean field -> { boolean: true, type: "boolean", name: "isDone" }
string field -> { string: true, type: "string", name: "description"}

We need to have "boolean: true" part to achieve conditional rendering with Mustache - in
Mustache template we cannot check if type == "boolean", but only whether a "boolean" property
is set or not.
-}
entityFieldToJsonWithTypeAsKey :: EntityField -> Aeson.Value
entityFieldToJsonWithTypeAsKey entityField = addEntityFieldTypeToJsonAsKeyWithValueTrue
                                                (entityFieldType entityField)
                                                (Aeson.toJSON entityField)

-- | Adds "FIELD_TYPE: true" to a given json. This is needed for Mustache so we can differentiate
-- between the form fields of different types.
addEntityFieldTypeToJsonAsKeyWithValueTrue :: EntityFieldType -> Aeson.Value -> Aeson.Value
addEntityFieldTypeToJsonAsKeyWithValueTrue efType json =
    Util.jsonSet (toText efType) (Aeson.toJSON True) json
    where
        toText = Text.pack . show
