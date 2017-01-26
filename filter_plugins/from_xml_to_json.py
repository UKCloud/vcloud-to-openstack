import json
from xml.dom import minidom

def from_xml_to_json(xmlstr):
  if type(xmlstr) != StringType:
    raise errors.AnsibleFilterError("|failed expects a String")

  dom = minidom.parseString(xmlstr)
  return json.dumps(parse_element(dom), sort_keys=True, indent=2)

def parse_element(element):
    dict_data = dict()
    if element.nodeType == element.TEXT_NODE:
        dict_data['data'] = element.data
    if element.nodeType not in [element.TEXT_NODE, element.DOCUMENT_NODE, 
                                element.DOCUMENT_TYPE_NODE]:
        for item in element.attributes.items():
            dict_data[item[0]] = item[1]
    if element.nodeType not in [element.TEXT_NODE, element.DOCUMENT_TYPE_NODE]:
        for child in element.childNodes:
            child_name, child_dict = parse_element(child)
            if child_name in dict_data:
                try:
                    dict_data[child_name].append(child_dict)
                except AttributeError:
                    dict_data[child_name] = [dict_data[child_name], child_dict]
            else:
                dict_data[child_name] = child_dict 
    return element.nodeName, dict_data

class FilterModule (object):
  def filters(self):
    return {"from_xml_to_json": from_xml_to_json}