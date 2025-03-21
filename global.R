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
  times = list(start = 2011, end = 2061),
  modules = c(
    "PredictiveEcology/Biomass_speciesFactorial@development",
    "PredictiveEcology/Biomass_borealDataPrep@development",
    "PredictiveEcology/Biomass_speciesParameters@development",
    "DominiqueCaron/Biomass_yieldTables@reorganisation",
    "PredictiveEcology/Biomass_core@main",
    "DominiqueCaron/LandRCBM_split3pools@restructuration"
  ),
  params = list(
    .globals = list(
      dataYear = 2011, #will get kNN 2011 data, and NTEMS 2011 landcover
      .plots = c("png"),
      .plotInterval = 10,
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
      moduleNameAndBranch = "PredictiveEcology/Biomass_core@main",
      .plots = "png",
      .useCache = "generateData"
    )
  ),
  packages = c("googledrive", 'RCurl', 'XML', "stars"),
  useGit = F,
  functions = "R/getRIA.R",
  # Study area is RIA
  studyAreaLarge = {
    reproducible::prepInputs(
      url = "https://drive.google.com/file/d/1LxacDOobTrRUppamkGgVAUFIxNT4iiHU/view?usp=sharing",
      destinationPath = "inputs",
      fun = getRIA,
      overwrite = TRUE
    )
  }, 
  studyArea = studyAreaLarge, rasterToMatch = {
    targetCRS <- terra::crs(studyArea)
    rtm <- terra::rast(studyArea, res = c(250, 250), crs = targetCRS)
    rtm[] <- 1
    rtm <- terra::mask(rtm, studyArea)
    rtm
  }, 
  # studyArea = {
  #   reproducible::prepInputs(url = "https://drive.google.com/file/d/1LxacDOobTrRUppamkGgVAUFIxNT4iiHU/view?usp=sharing",
  #                            destinationPath = "inputs",
  #                            fun = sf::st_read,
  #                            overwrite = TRUE) |>
  #     terra::vect() |>
  #     terra::crop(terra::ext(1150000, 1200000, 1250000, 1300000)) |>
  #     terra::aggregate()
  # },
  # studyAreaLarge = studyArea,
  rasterToMatch = {
    targetCRS <- terra::crs(studyArea)
    rtm<- terra::rast(studyArea, res = c(250, 250), crs = targetCRS)
    rtm[] <- 1
    rtm <- terra::mask(rtm, studyArea)
    rtm
  },
  sppEquiv = {
    speciesInStudy <- LandR::speciesInStudyArea(studyAreaLarge,
                                                dPath = "inputs")
    species <- LandR::equivalentName(speciesInStudy$speciesList, df = LandR::sppEquivalencies_CA, "LandR")
    sppEquiv <- LandR::sppEquivalencies_CA[LandR %in% species]
    sppEquiv <- sppEquiv[KNN != "" & LANDIS_traits != ""] #avoid a bug with shore pine
  }
)


out$loadOrder <- unlist(out$modules)

initOut <- SpaDES.core::simInit2(out)
simOut <- SpaDES.core::spades(initOut)
