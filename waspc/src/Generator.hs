module Generator
       ( writeWebAppCode
       ) where

import qualified Data.Text
import qualified Data.Text.IO
import Data.Time.Clock
import qualified Paths_waspc
import qualified Data.Version
import Control.Monad (mapM_)
import Path ((</>), relfile)
import qualified Path
import qualified Path.Aliases as Path

import CompileOptions (CompileOptions)
import Wasp (Wasp)
import Generator.Generators (generateWebApp)
import Generator.FileDraft (FileDraft, write)


-- | Generates web app code from given Wasp and writes it to given destination directory.
--   If dstDir does not exist yet, it will be created.
--   NOTE(martin): What if there is already smth in the dstDir? It is probably best
--     if we clean it up first? But we don't want this to end up with us deleting stuff
--     from user's machine. Maybe we just overwrite and we are good?
writeWebAppCode :: Wasp -> Path.AbsDir -> CompileOptions -> IO ()
writeWebAppCode wasp dstDir compileOptions = do
    writeFileDrafts dstDir (generateWebApp wasp compileOptions)
    writeDotWaspInfo dstDir

-- | Writes file drafts while using given destination dir as root dir.
--   TODO(martin): We could/should parallelize this.
--     We could also skip writing files that are already on the disk with same checksum.
writeFileDrafts :: Path.AbsDir -> [FileDraft] -> IO ()
writeFileDrafts dstDir fileDrafts = mapM_ (write dstDir) fileDrafts

-- | Writes .waspinfo, which contains some basic metadata about how/when wasp generated the code.
writeDotWaspInfo :: Path.AbsDir -> IO ()
writeDotWaspInfo dstDir = do
    currentTime <- getCurrentTime
    let version = Data.Version.showVersion Paths_waspc.version
    let content = "Generated on " ++ (show currentTime) ++ " by waspc version " ++ (show version) ++ " ."
    let dstPath = dstDir </> [relfile|.waspinfo|]
    Data.Text.IO.writeFile (Path.toFilePath dstPath) (Data.Text.pack content)
