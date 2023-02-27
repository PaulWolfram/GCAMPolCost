# GCAMPolCost
If you use this add-on script in your own work please cite: `https://www.researchsquare.com/article/rs-2074134/v1`.

Currently GCAM does not allow to calculate policy cost if GCAM is not run until 2100. This tool can be used to query policy costs from a GCAM scenario run that stops after 2050 and the tool can be tailored to other years as well. The tool is written in `R` and it can be used to parse an `.xml` file that contains the policy cost. The corresponding file is called `cost_curves[scenario name].xlm` and can be found in the `gcam-core/exe` folder after running a scenario. The `.xml` file is created automatically during a scenario run if `createCostCurve` in the configuration file has been enabled (set to 1) beforehand: `<Value name="createCostCurve">1</Value>`. 

Policy cost is the integral of the carbon price times the amount of abated emissions (see here for more detail: `https://jgcri.github.io/gcam-doc/policies.html`). In order to reduce computational time, the area under the curve is estimated for five carbon price levels: 0%, 20%, 40%, 60%, 80%, and 100% of the carbon price in each time period. For more information on how policy costs are calculated, please refer to the subsection "Policy cost" in the following pre-print: `https://www.researchsquare.com/article/rs-2074134/v1`.

