# GCAMPolCost
If you use this add-on script in your own work please cite: `https://www.researchsquare.com/article/rs-2074134/v1`.

This tool can be used to query policy costs from a GCAM scenario run. The tool is written in `R` and it can be used to parse an `.xml` file that contains the policy cost. The corresponding file is called `cost_curves[scenario name].xlm` and can be found in the `gcam-core/exe` folder after running a scenario. The `.xml` file is created automatically when `createCostCurve` in the configuration file is enabled (set to 1): `<Value name="createCostCurve">1</Value>`. 

Policy costs are the integral over the carbon price times the amount of abated emissions. In order to reduce computational time, the area under the curve is estimated for five carbon price levels: 0%, 20%, 40%, 60%, 80%, and 100% of the carbon price. For more information on how policy costs are calculated, please refer to the Methods section in: `https://www.researchsquare.com/article/rs-2074134/v1`.

