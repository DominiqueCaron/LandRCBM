###
###
# This script runs LandR and CBM in a small area in RIA.
###
###

# Get the minimal amount of packages
repos <- c("predictiveecology.r-universe.dev", getOption("repos"))
if (!require("SpaDES.project")){
  Require::Install(c("SpaDES.project", "SpaDES.core", "reproducible"), repos = repos, dependencies = TRUE)
}

out <- SpaDES.project::setupProject(
  paths = list(projectPath = getwd(),
               inputPath = "inputs",
               outputPath = "outputs/LandRCBM_RIAsmall",
               cachePath = "cache"),
  options = options(spades.moduleCodeChecks = FALSE,
                    spades.recoveryMode = FALSE),
  times = list(start = 2011, end = 2011),
  modules = c(
    "PredictiveEcology/Biomass_speciesFactorial@development",
    "PredictiveEcology/Biomass_borealDataPrep@development",
    "PredictiveEcology/Biomass_speciesParameters@development",
    "PredictiveEcology/CBM_defaults@development",
    "PredictiveEcology/CBM_dataPrep_RIA@presentDay",
    "PredictiveEcology/Biomass_yieldTables@main",
    "PredictiveEcology/Biomass_core@main",
    "PredictiveEcology/LandRCBM_split3pools@master",
    "PredictiveEcology/CBM_core@development"
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
    )|> sf::st_crop(c(xmin = 1000000, xmax = 1200000, ymin = 1100000, ymax = 1300000))
  }, 
  studyAreaLarge = studyArea,
  rasterToMatch = {
    sa <- terra::vect(studyArea)
    targetCRS <- terra::crs(sa)
    rtm <- terra::rast(sa, res = c(250, 250))
    terra::crs(rtm) <- targetCRS
    rtm[] <- 1
    rtm <- terra::mask(rtm, sa)
    rtm
  },
  masterRaster = rasterToMatch,
  sppEquiv = {
    speciesInStudy <- LandR::speciesInStudyArea(studyArea,
                                                dPath = "inputs")
    species <- LandR::equivalentName(speciesInStudy$speciesList, df = LandR::sppEquivalencies_CA, "LandR")
    sppEquiv <- LandR::sppEquivalencies_CA[LandR %in% species]
    sppEquiv <- sppEquiv[KNN != "" & LANDIS_traits != ""] #avoid a bug with shore pine
  },
  disturbanceRastersURL = "https://drive.google.com/file/d/12YnuQYytjcBej0_kdodLchPg7z9LygCt",
  params = list(
    .globals = list(
      dataYear = 2011, #will get kNN 2011 data, and NTEMS 2011 landcover
      .plots = c("png"),
      .plotInterval = 25,
      sppEquivCol = 'LandR',
      .studyAreaName = "RIA"
    ),
    Biomass_borealDataPrep = list(
      .studyAreaName = "RIA",
      subsetDataBiomassModel = 50
    ),
    Biomass_speciesFactorial = list(
      .plots = NULL, #"pdf",
      runExperiment = TRUE,
      factorialSize = "medium"
    ),
    Biomass_speciesParameters = list(
      .plots = "png",
      standAgesForFitting = c(0, 125),
      .useCache = c(".inputObjects", "init"),
      speciesFittingApproach = "focal"
    ),
    Biomass_yieldTables = list(
      moduleNameAndBranch = "PredictiveEcology/Biomass_core@development",
      .plots = "png",
      .useCache = "generateData"
    )
  )
)

out$loadOrder <- unlist(out$modules)

initOut <- SpaDES.core::simInit2(out)
simOut <- SpaDES.core::spades(initOut)