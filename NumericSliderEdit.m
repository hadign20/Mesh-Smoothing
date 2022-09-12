classdef NumericSliderEdit < handle
    properties
        slider
        edit
        valueChangedFcn
        
        is_integer
    end
    
    methods
        function obj = NumericSliderEdit(parent,position,min_value,max_value,valueChangedFcn)
            obj.valueChangedFcn = valueChangedFcn;
            slider_pos = position;
            slider_pos(3) = position(3)-45;
            edit_pos = position;
            edit_pos(1) = position(1)+slider_pos(3)+5;
            edit_pos(3) = position(3)-slider_pos(3)-5;
            obj.slider = uicontrol(parent,'Style','slider',...
                'Position',slider_pos,'Units','normalized',...
                'Min',min_value,'Max',max_value,'SliderStep',[0.02 0.1],...
                'Callback',@obj.sliderChanged,'Value',max_value);
            obj.edit = uicontrol(parent,'Style','edit',...
                'Position',edit_pos,'Units','normalized',...
                'String',max_value,'UserData',max_value, ...
                'Callback',@obj.editChanged,'HorizontalAlignment','left');
        end
        
        function setSliderStep(obj,val)
            obj.slider.SliderStep = val;
        end
        
        function setMin(obj,val)
            obj.slider.Min = val;
            if obj.slider.Value < obj.slider.Min
                obj.setValue(obj.slider.Min);
            end
        end
        
        function setMax(obj,val)
            obj.slider.Max = val;
            if obj.slider.Value > obj.slider.Max
                obj.setValue(obj.slider.Max);
            end
        end
        
        function setInteger(obj,val)
            obj.is_integer = val;
        end
        
        function sliderChanged(obj,source,data)
            if obj.is_integer
                val = round(source.Value);
            else
                val = source.Value;
            end
            obj.edit.String = val;
            obj.valueChangedFcn(val);
        end
        
        function editChanged(obj,source,data)
            val = str2double(source.String);
            if isnan(val)
                source.String = source.UserData;
            else
                if obj.is_integer
                    val = round(val);
                end
                if val < obj.slider.Min
                    obj.slider.Value = obj.slider.Min;
                elseif val > obj.slider.Max
                    obj.slider.Value = obj.slider.Max;
                else
                    obj.slider.Value = val;
                end
                source.UserData = source.String;
                obj.valueChangedFcn(val);
            end
        end
        
        function setValue(obj,val)
            if obj.is_integer
                val = round(val);
            end
            val = min(max(val, obj.slider.Min), obj.slider.Max);
            obj.edit.String = val;
            obj.edit.UserData = val;
            obj.slider.Value = val;
            obj.valueChangedFcn(val);
        end
    end
end