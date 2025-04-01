###
###
# This script runs the module LandRCBM_split3pools on its own.
###
###

Require::Require("PredictiveEcology/SpaDES.core")
# Get the minimal amount of packages
repos <- c("predictiveecology.r-universe.dev", getOption("repos"))

## Objects
parameters <- list(
  LandRCBM_split3pools = list(.useCache = ".inputObjects", .plots = "png",
                              .plotInterval = 3)
)

modules <- list("LandRCBM_split3pools")

# All the action is here
split3poolsInit <- simInit(
  params = parameters,
  modules = modules,
  paths = list(modulePath = "modules/",
               inputPath = "inputs/",
               outputPath = "outputs/split3poolsDefault",
               cache = "cache")
)

split3poolsSim <- spades(split3poolsInit)
