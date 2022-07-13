import { v4 as uuidv4 } from 'uuid';

  /**
   * @class An abstraction for the basic information shared by many classes.
   * This class will generate UUIDs for the new instance.
   * @param name The name to be set.
   * @param description The description to be set.
   */
export class BasicInfo {
  id: string;
  name: string;
  description: string;

  constructor(
    name: string,
    description: string,
    ) {
      this.id = uuidv4();
      this.name = name;
      this.description = description;
    }

}
