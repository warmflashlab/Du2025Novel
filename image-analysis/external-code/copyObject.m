function objNew = copyObject(obj)
% makes a deep copy of an object. 
% needed because objects inherited from handle class are only references
% if you define an object x and then y = x. x and y refernece the same
% underlying object, so changing one will change the other. 

objType = class(obj);
mc = metaclass(obj);
props = {mc.PropertyList.Name};
isdepend = [mc.PropertyList.Dependent];
access = {mc.PropertyList.SetAccess};
isprotected = contains(access,'protected');
objNew = feval(objType);

for pp = 1:length(props)
    if ~isdepend(pp) && ~isprotected(pp)
        objNew.(props{pp}) = obj.(props{pp});
    end
end