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
  times = list(start = 1985, end = 2015),
  modules = c(
    "PredictiveEcology/Biomass_speciesFactorial@development",
    "PredictiveEcology/Biomass_borealDataPrep@development",
    "PredictiveEcology/Biomass_speciesParameters@development",
    "PredictiveEcology/CBM_defaults@development",
    "PredictiveEcology/Biomass_regeneration@development",
    "PredictiveEcology/Biomass_yieldTables@main",
    "PredictiveEcology/Biomass_core@development",
    "PredictiveEcology/CBM_dataPrep@suz-distRasters",
    "DominiqueCaron/LandRCBM_split3pools@run-with-CBM",
    "DominiqueCaron/CBM_core@LandRCBM-simplify-core",
    file.path("PredictiveEcology/scfm@development/modules",
              c("scfmDataPrep",
                "scfmIgnition", "scfmEscape", "scfmSpread",
                "scfmDiagnostics"))
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
  studyAreaCalibration = sf::st_buffer(studyArea, dist = 10^5),
  rasterToMatch = {
    sa <- terra::vect(studyArea)
    targetCRS <- terra::crs(sa)
    rtm <- terra::rast(sa, res = c(250, 250))
    terra::crs(rtm) <- targetCRS
    rtm[] <- 1
    rtm <- terra::mask(rtm, sa)
    rtm
  },
  masterRaster = {
    masterRaster = rasterToMatch
    names(masterRaster) <- "ldSp_TestArea"
    masterRaster
  },
  rasterToMatchCalibration = {
    sac <- terra::vect(studyAreaCalibration)
    targetCRS <- terra::crs(sac)
    rtmc <- terra::rast(sac, res = c(250, 250))
    terra::crs(rtmc) <- targetCRS
    rtmc[] <- 1
    rtmc <- terra::mask(rtmc, sac)
    rtmc
  },
  sppEquiv = {
    speciesInStudy <- LandR::speciesInStudyArea(studyArea,
                                                dPath = "inputs")
    species <- LandR::equivalentName(speciesInStudy$speciesList, df = LandR::sppEquivalencies_CA, "LandR")
    sppEquiv <- LandR::sppEquivalencies_CA[LandR %in% species]
    sppEquiv <- sppEquiv[KNN != "" & LANDIS_traits != ""] #avoid a bug with shore pine
  },
  disturbanceMeta = data.table(
    eventID = 1,
    wholeStand = 1,
    disturbance_type_id = 1,
    distName = "Wildfire",
    objectName = "rstCurrentBurn",
    delay = 1
  ),
  outputs = as.data.frame(expand.grid(
    objectName = c("cbmPools", "NPP"),
    saveTime   = sort(c(times$start, times$start + c(1:(times$end - times$start))))
  )),
  params = list(
    .globals = list(
      dataYear = 2001, #will get kNN 2011 data, and NTEMS 2011 landcover
      .plots = c("png"),
      .plotInterval = 10,
      sppEquivCol = 'LandR',
      .studyAreaName = "RIA"
    ),
    CBM_core = list(
      skipCohortGroupHandling = TRUE,
      skipPrepareCBMvars = TRUE
    ),
    Biomass_borealDataPrep = list(
      overrideAgeInFires = FALSE,
      overrideBiomassInFires = FALSE,
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
    ),
    scfmDataPrep = list(targetN = 4000,
                        flammabilityThreshold = 0.05,
                        .useParallelFireRegimePolys = FALSE,
                        fireEpoch = c(1971, 2020),
                        fireRegimePolysType = "FRU"
    )
  )
)

out$loadOrder <- unlist(out$modules)

initOut <- SpaDES.core::simInit2(out)
simOut <- SpaDES.core::spades(initOut)
