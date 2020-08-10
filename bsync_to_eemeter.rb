#######################################################
# 
# 
# 
#######################################################

require 'csv'
require 'rexml/document'
require 'fileutils'
require 'json'
require 'date'
require 'time'


# Read BSync file and write to eemeter 'il-electricity-cdd-hdd-daily.csv' format:
bsync_xml = File.new("spec/tests/nmec_sample_BSync.xml")
doc = REXML::Document.new(bsync_xml)
CSV.open('bsync_sample.csv', 'w', :write_headers => true, :headers => ["start", "value"]) do |row|
  doc.elements.each("auc:BuildingSync/auc:Facilities/auc:Facility/auc:Reports/auc:Report/auc:Scenarios/auc:Scenario") do |scenario|
    if scenario.attributes["ID"] == "Measured"
      REXML::XPath.match(scenario, "//auc:ReferenceCase").each do |reference_case|
        if reference_case.attributes["IDref"] == "Baseline"
          # puts "#{scenario.elements["auc:ScenarioType/auc:PackageOfMeasures/auc:ReferenceCase"].attributes["IDref"] == "Baseline"}"
          # puts "#{REXML::XPath.first(scenario, "//auc:ReferenceCase").attributes["IDref"]}"
          scenario.elements.each("auc:TimeSeriesData/auc:TimeSeries") do |ts_data|
            # Ideally "auc:StartTimestamp"
            row << [ts_data.elements["auc:EndTimestamp"].text.to_s, ts_data.elements["auc:IntervalReading"].text.to_s]
          end
        end
      end
    end
  end
end

# create a metadata.json that includes baseline start/end dates and reporting start/end dates
baseline_start_date, baseline_end_date, report_start_date, report_end_date = ""
derived_model = REXML::XPath.first(doc, "//auc:BuildingSync/auc:Facilities/auc:Facility/auc:Reports/auc:Report/auc:Scenarios/auc:DerivedModels")
REXML::XPath.match(derived_model, "//auc:DerivedModelPeriod").each do |model|
  if model.text == "Baseline"
    baseline_start_date = REXML::XPath.first(model, "//auc:BaselinePeriodStartDate").text
    baseline_end_date = REXML::XPath.first(model, "//auc:BaselinePeriodEndDate").text
    report_start_date = REXML::XPath.first(model, "//auc:ReportingPeriodStartDate").text
    report_end_date = REXML::XPath.first(model, "//auc:ReportingPeriodEndDate").text
  end
end

hash = {
  "baseline_start_date" => baseline_start_date,
  "baseline_end_date" => baseline_end_date,
  "report_start_date" => report_start_date,
  "report_end_date" => report_end_date
}
File.open("metadata.json", "w") do |f|
  f.write(hash.to_json)
end

exec("python eemeter_daily.py 'bsync_sample.csv' 'metadata.json'")
