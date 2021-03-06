module Wasp.JsImport
    ( JsImport(..)
    ) where

import Data.Aeson ((.=), object, ToJSON(..))
import qualified Path.Aliases as Path


-- | Represents javascript import -> "import <what> from <from>".
data JsImport = JsImport
    { jsImportWhat :: !String
    -- | Path of file to import, relative to external code directory.
    --   So for example if jsImportFrom is "test.js", we expect file
    --   to exist at <external_code_dir>/test.js.
    --   TODO: Make this more explicit in the code (both here and in wasp lang)? Also, support importing npm packages?
    , jsImportFrom :: !Path.RelFile
    } deriving (Show, Eq)

instance ToJSON JsImport where
    toJSON jsImport = object
        [ "what" .= jsImportWhat jsImport
        , "from" .= jsImportFrom jsImport
        ]
