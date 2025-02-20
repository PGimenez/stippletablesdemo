using GenieFramework
@genietools
using StippleTables, DataFrames

df = DataFrame(
    ID = 1:20,
    Department = repeat(["Sales", "Marketing", "IT", "HR"], 5),
    Employee = ["Emp" * string(i) for i in 1:20],
    Salary = rand(50000:5000:100000, 20),
    Sales = rand(50000:5000:100000, 20),
    HireDate = Date(2020,1,1) .+ Day.(rand(1:1000, 20)),
    Performance = rand(["Excellent", "Good", "Average", "Poor"], 20)
)
@app begin
    @out title= "Employee data"
    @out table = DataTable(df)
    # data grouping
    @in group_by::Any = "Department"
    @out group_by_options = ["Department", "HireDate", "Performance"]
    @in groupkeys::Vector{Any} = unique(df[!, :Department])
    @in selectedkey::Any = "Sales"
    # data aggregation
    @in aggregate_by::Vector{String} = []
    @out aggregate_by_options = ["Employee", "Department", "Performance"]
    @in aggregate_target = ""
    @out aggregate_target_options = ["Salary", "Sales"]

    @onchange group_by begin
        @show group_by
        if group_by == ""
            groupkeys = []
            table = DataTable(df)
        else
            groupkeys = unique(df[:,group_by])
            selectedkey = first(groupkeys)
        end
        # reset aggregation settings when in group mode
        aggregate_by[!] = []; aggregate_target[!] = ""
        @push aggregate_by; @push aggregate_target
   end

    @onchange selectedkey begin
       # the grouping is performed when a new key is selected to avoid having to store
       # the grouped dataframe. For small dataframes, you can store the gdf in a @private variable
       # and use this handler to pick a group from it
       table = groupby(df, group_by)[(selectedkey,)] |> DataFrame |> DataTable
    end

    @onchange aggregate_by begin
        @show aggregate_by
        if aggregate_by == []
            table = DataTable(df)
            aggregate_target = ""
        else
            aggregate_target = first(aggregate_target_options)
        end
        # reset grouping settings when in aggregate mode
        group_by[!] = ""
        @push group_by
    end
    @onchange aggregate_target begin
        if aggregate_target != ""
            gdf = groupby(df, aggregate_by)
            table = combine(gdf, aggregate_target => sum => aggregate_target) |> DataTable
          end
    end
end

ui() ="""
<h4> Table search</h4>
<st-table 
    :data='table.data' 
    :columns='table.columns' 
    :title="title" 
    :search="true" 
    :searchcolumns="true" 
    :showcontrols="true" 

/>
<h4> Table with data grouping and search</h4>
<st-table 
    :data='table.data' 
    :columns='table.columns' 
    :title="title" 
    :search="true" 
    :searchcolumns="true" 
    :showcontrols="true" 
    :groupby.sync="group_by"
    :groupbyoptions="group_by_options" 
    :groupkeys="groupkeys"
    :selectedkey="selectedkey"
/>
<h4> Table with data aggretation, grouping and search</h4>
<st-table 
    :data='table.data' 
    :columns='table.columns' 
    :title="title" 
    :search="true" 
    :searchcolumns="true" 
    :showcontrols="true" 
    :rows-per-page-options="[10, 20, 50]" 
    :groupby.sync="group_by"
    :groupbyoptions="group_by_options" 
    :groupkeys="groupkeys"
    :selectedkey="selectedkey"
    :aggregateby.sync="aggregate_by"
    :aggregatebyoptions="aggregate_by_options"
    :aggregatetarget.sync="aggregate_target"
    :aggregatetargetoptions="aggregate_target_options"
/>
""" 

@page("/", ui)
