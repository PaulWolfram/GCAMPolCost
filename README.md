# GCAMPolCost
This tool can be used to query policy costs from a GCAM scenario run. The tool is written in `R` and it can be used to parse an `.xml` file that contains the policy cost. The corresponding file is called `cost_curves[scenario name].xlm` and can be found in the `gcam-core/exe` folder. The `.xml` file is created automatically when `createCostCurve` in the configuration file is enabled (set to 1): `<Value name="createCostCurve">1</Value>`. 
