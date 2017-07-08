
Rotorbar.options = CreateFrame( "Frame", "RotorbarOptions", UIParent );
-- Register in the Interface Addon Options GUI
-- Set the name for the Category for the Options Panel
Rotorbar.options.name = "Rotorbar";
-- Add the options to the Interface Options
InterfaceOptions_AddCategory(Rotorbar.options);

-- Make a child options
Rotorbar.childoptions = CreateFrame( "Frame", "RotorbarChild", Rotorbar.options);
Rotorbar.childoptions.name = "Rotorbar Child";
-- Specify childness of this options (this puts it under the little red [+], instead of giving it a normal AddOn category)
Rotorbar.childoptions.parent = Rotorbar.options.name;
-- Add the child to the Interface Options
InterfaceOptions_AddCategory(Rotorbar.childoptions);