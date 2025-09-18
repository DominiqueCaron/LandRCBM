# LandRCBM

Here is a collection of examples running LandRCBM with different settings. 

## global_testData
Prepares the inputs for LandRCBM for a small test area () within RIA (regional integrated assessment -  5 timber supply areas in the NE corner of British-Columbia) for 2000. The modules Biomass_core, LandRCBM_split3pools and  CBM_core and not called in this script. The outputs are used in the integration tests of LandRCBM (within CBM_core and LandRCBM_split3pools).

## global_scfm
Runs LandR Biomass and spadesCBM with SCFM for a small test area () within RIA. The simulation uses the most of default inputs to estimate carbon between 1985 and 2015. 

## global_yieldTables
Creates yield tables for the entire RIA region.

## global_noDist
Runs LandR Biomass and spadesCBM without disturbances for a small test area () within RIA. 

## global_histFires
Runs LandR Biomass and spadesCBM with historical disturbances (NTEMS) for a small area () within the Northwest Territories. It estimates carbon between 2011 and 2020. 

## Benchmarks
All computation time and memory benchmarks are for the spades call without any operation cached and are estimated using `profvis`.

As of Sep 17 2025:

| Script             | Running time  | Maximum RAM |
| ------------------ | ------------- | ----------- |
| global_testData    | 3 min         | 3.5 GB      |
| global_scfm        | 4h 12min      |             |
| global_yieldTables | 1h 50min      |
| global_noDist      |               |             |
| global_histFires   |               |             |
