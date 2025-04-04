# Get the minimal amount of packages
repos <- c("predictiveecology.r-universe.dev", getOption("repos"))
if (!require("SpaDES.project")){
  Require::Install(c("SpaDES.project", "SpaDES.core", "reproducible"), repos = repos, dependencies = TRUE)
}

out <- SpaDES.project::setupProject(
  paths = list(projectPath = getwd(),
               inputPath = "inputs",
               outputPath = "outputs",
               cachePath = "cache"),
  options = options(spades.moduleCodeChecks = FALSE,
                    spades.recoveryMode = FALSE),
  times = list(start = 2011, end = 2211),
  modules = c(
    "PredictiveEcology/CBM_defaults",
    "DominiqueCaron/LandRCBM_split3pools@prepForCBM",
    "PredictiveEcology/CBM_dataPrep_RIA"
  ),
  packages = c("googledrive", 'RCurl', 'XML', "stars", "httr2"),
  useGit = F,
  functions = "R/getRIA.R",
  # Study area is RIA
  studyArea = {
    reproducible::prepInputs(
      url = "https://drive.google.com/file/d/1LxacDOobTrRUppamkGgVAUFIxNT4iiHU/view?usp=sharing",
      destinationPath = "inputs",
      fun = getRIA,
      overwrite = TRUE
    )#|> sf::st_crop(c(xmin = 1000000, xmax = 1200000, ymin = 1100000, ymax = 1300000))
  }, 
  rasterToMatch = {
    targetCRS <- terra::crs(studyArea)
    rtm <- terra::rast(terra::vect(studyArea), res = c(250, 250))
    terra::crs(rtm) <- targetCRS
    rtm[] <- 1
    rtm <- terra::mask(rtm, terra::vect(studyArea))
    rtm
  },
  params = list(
    .globals = list(
      dataYear = 2011, #will get kNN 2011 data, and NTEMS 2011 landcover
      .plots = c("png"),
      .plotInterval = 25,
      .studyAreaName = "RIA"
    )
  )
)

out$loadOrder <- unlist(out$modules)

initOut <- SpaDES.core::simInit2(out)
simOut <- SpaDES.core::spades(initOut)
